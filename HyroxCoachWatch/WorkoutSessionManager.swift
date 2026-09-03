// E1.2: active HKWorkoutSession timer and live heart-rate probe.

import Foundation
import Combine
import HealthKit
import OSLog

@MainActor
final class WorkoutSessionManager: NSObject, ObservableObject {
    @Published private(set) var tickCount = 0
    @Published private(set) var elapsedByTicks: TimeInterval = 0
    @Published private(set) var elapsedByDate: TimeInterval = 0
    @Published private(set) var latestHeartRate: Double?
    @Published private(set) var isStarting = false
    @Published private(set) var isRunning = false
    @Published private(set) var isEnding = false
    @Published private(set) var latestResult = "Not started"
    /// E2.3 needs the session's start instant as the anchor for segment offsets.
    /// HKWorkoutSession exposes no stable UUID before the workout is finished,
    /// so the start date is the only identity available while it is running.
    @Published private(set) var sessionStartDate: Date?

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var timer: Timer?
    private var startDate: Date?

    // Activity type affects categorisation and energy estimation, not whether the
    // session keeps the app alive. HYROX has no dedicated HKWorkoutActivityType.
    func start(activityType: HKWorkoutActivityType = .crossTraining) {
        guard session == nil else {
            latestResult = "A workout session already exists"
            AppLog.workout.error("\(AppLog.stamp(), privacy: .public) E1.2 start ignored: session already exists")
            return
        }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType
        configuration.locationType = .indoor

        do {
            let newSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let newBuilder = newSession.associatedWorkoutBuilder()
            newSession.delegate = self
            newBuilder.delegate = self
            newBuilder.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )

            session = newSession
            builder = newBuilder
            resetElapsed()
            isStarting = true

            let start = Date()
            startDate = start
            sessionStartDate = start
            newSession.startActivity(with: start)
            AppLog.workout.info("\(AppLog.stamp(), privacy: .public) E1.2 session start requested activityType=\(activityType.rawValue)")

            newBuilder.beginCollection(withStart: start) { [weak self] success, error in
                Task { @MainActor in
                    guard let self else { return }
                    self.isStarting = false
                    if success {
                        self.isRunning = true
                        self.latestResult = "Workout collection running"
                        self.startTimer()
                        AppLog.workout.info("\(AppLog.stamp(), privacy: .public) E1.2 builder collection began")
                    } else {
                        self.latestResult = "Collection failed: \(error?.localizedDescription ?? "unknown error")"
                        AppLog.workout.error("\(AppLog.stamp(), privacy: .public) E1.2 begin collection failed: \(error?.localizedDescription ?? "unknown error", privacy: .public)")
                        self.cleanUpSession()
                    }
                }
            }
        } catch {
            latestResult = "Session creation failed: \(error.localizedDescription)"
            AppLog.workout.error("\(AppLog.stamp(), privacy: .public) E1.2 session creation failed: \(error.localizedDescription, privacy: .public)")
            cleanUpSession()
        }
    }

    func end(metadata: [String: String]? = nil) {
        guard let session, let builder, !isEnding else {
            latestResult = self.session == nil ? "No workout session to end" : latestResult
            return
        }

        isEnding = true
        isStarting = false
        isRunning = false
        stopTimer()
        let endDate = Date()
        latestResult = "Ending workout…"
        AppLog.workout.info("\(AppLog.stamp(), privacy: .public) E1.2 ending session")
        session.end()

        // HealthKit's activityType is a fixed Apple enum with no HYROX case, so
        // every session is permanently recorded as .crossTraining. The brand-name
        // key is the only place a workout can carry a name that enum does not
        // cover. Whether it surfaces in Apple's own Health UI is untested.
        //
        // Added here rather than in ProtocolMachine because that type is
        // deliberately independent of HealthKit — it owns the semantic record,
        // and HealthKit-specific keys belong on this side of the boundary.
        var metadata = metadata
        if metadata != nil {
            metadata?[HKMetadataKeyWorkoutBrandName] = "HYROX"
        }

        if let metadata, !metadata.isEmpty {
            let keyCount = metadata.count
            builder.addMetadata(metadata) { [weak self] success, error in
                Task { @MainActor in
                    guard let self else { return }
                    if success {
                        AppLog.workout.info("\(AppLog.stamp(), privacy: .public) E1.2 metadata attached keys=\(keyCount, privacy: .public)")
                        self.finish(
                            builder: builder,
                            endDate: endDate,
                            metadataKeyCount: keyCount,
                            metadataError: nil
                        )
                    } else {
                        let message = error?.localizedDescription ?? "unknown error"
                        self.latestResult = "Metadata failed (\(keyCount) keys): \(message); finishing workout…"
                        AppLog.workout.error("\(AppLog.stamp(), privacy: .public) E1.2 metadata attach failed keys=\(keyCount, privacy: .public): \(message, privacy: .public)")
                        self.finish(
                            builder: builder,
                            endDate: endDate,
                            metadataKeyCount: keyCount,
                            metadataError: message
                        )
                    }
                }
            }
        } else {
            finish(
                builder: builder,
                endDate: endDate,
                metadataKeyCount: 0,
                metadataError: nil
            )
        }
    }

    private func finish(
        builder: HKLiveWorkoutBuilder,
        endDate: Date,
        metadataKeyCount: Int,
        metadataError: String?
    ) {
        let metadataResult: String
        if let metadataError {
            metadataResult = "metadata not attached (\(metadataKeyCount) keys): \(metadataError)"
        } else if metadataKeyCount > 0 {
            metadataResult = "metadata attached (\(metadataKeyCount) keys)"
        } else {
            metadataResult = "metadata not attached (0 keys)"
        }

        builder.endCollection(withEnd: endDate) { [weak self] success, error in
            Task { @MainActor in
                guard let self else { return }
                guard success else {
                    self.latestResult = "End collection failed: \(error?.localizedDescription ?? "unknown error"); \(metadataResult)"
                    AppLog.workout.error("\(AppLog.stamp(), privacy: .public) E1.2 end collection failed: \(error?.localizedDescription ?? "unknown error", privacy: .public)")
                    self.cleanUpSession()
                    return
                }

                AppLog.workout.info("\(AppLog.stamp(), privacy: .public) E1.2 builder collection ended")
                do {
                    if let workout = try await builder.finishWorkout() {
                        self.latestResult = "Finished UUID \(workout.uuid.uuidString), duration \(String(format: "%.1f", workout.duration))s; \(metadataResult)"
                        AppLog.workout.info("\(AppLog.stamp(), privacy: .public) E1.2 workout finished UUID=\(workout.uuid.uuidString, privacy: .public) duration=\(workout.duration)")
                    } else {
                        self.latestResult = "Finish failed: no workout returned; \(metadataResult)"
                        AppLog.workout.error("\(AppLog.stamp(), privacy: .public) E1.2 finish failed: no workout returned")
                    }
                } catch {
                    self.latestResult = "Finish failed: \(error.localizedDescription); \(metadataResult)"
                    AppLog.workout.error("\(AppLog.stamp(), privacy: .public) E1.2 finish failed: \(error.localizedDescription, privacy: .public)")
                }
                self.cleanUpSession()
            }
        }
    }

    private func resetElapsed() {
        stopTimer()
        tickCount = 0
        elapsedByTicks = 0
        elapsedByDate = 0
        latestHeartRate = nil
        isEnding = false
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recordTick()
            }
        }
    }

    private func recordTick() {
        guard let startDate else { return }
        tickCount += 1
        elapsedByTicks = TimeInterval(tickCount)
        elapsedByDate = Date().timeIntervalSince(startDate)
        AppLog.workout.info("\(AppLog.stamp(), privacy: .public) E1.2 tick=\(self.tickCount) elapsedByTicks=\(self.elapsedByTicks) elapsedByDate=\(self.elapsedByDate)")
    }

    private func updateHeartRate(from workoutBuilder: HKLiveWorkoutBuilder) {
        guard
            let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate),
            let quantity = workoutBuilder.statistics(for: heartRateType)?.mostRecentQuantity()
        else { return }

        let beatsPerMinute = HKUnit.count().unitDivided(by: .minute())
        latestHeartRate = quantity.doubleValue(for: beatsPerMinute)
        AppLog.workout.info("\(AppLog.stamp(), privacy: .public) E1.2 heartRate=\(self.latestHeartRate ?? 0)")
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func cleanUpSession() {
        stopTimer()
        session?.delegate = nil
        builder?.delegate = nil
        session = nil
        builder = nil
        startDate = nil
        sessionStartDate = nil
        isRunning = false
        isStarting = false
        isEnding = false
    }
}

extension WorkoutSessionManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        AppLog.workout.info("\(AppLog.stamp(), privacy: .public) E1.2 session state \(fromState.rawValue) -> \(toState.rawValue) at \(date.description, privacy: .public)")
        Task { @MainActor [weak self] in
            guard let self else { return }
            if toState == .ended {
                self.isRunning = false
                self.stopTimer()
            }
        }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        AppLog.workout.error("\(AppLog.stamp(), privacy: .public) E1.2 session error: \(error.localizedDescription, privacy: .public)")
        Task { @MainActor [weak self] in
            self?.latestResult = "Session error: \(error.localizedDescription)"
            self?.cleanUpSession()
        }
    }
}

extension WorkoutSessionManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        AppLog.workout.info("\(AppLog.stamp(), privacy: .public) E1.2 builder collected workout event")
    }

    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        AppLog.workout.info("\(AppLog.stamp(), privacy: .public) E1.2 builder collected \(collectedTypes.count) data type(s)")
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              collectedTypes.contains(heartRateType) else { return }
        Task { @MainActor [weak self] in
            self?.updateHeartRate(from: workoutBuilder)
        }
    }
}
