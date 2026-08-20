// E1.0: HealthKit authorization and write/read-back probe.

import Foundation
import Combine
import HealthKit
import OSLog

@MainActor
final class HealthKitAuth: ObservableObject {
    let isAvailable = HKHealthStore.isHealthDataAvailable()

    @Published private(set) var authorizationResult = "Not requested"
    @Published private(set) var roundTripResult = "Not run"
    @Published private(set) var foreignReadResult = "Not run"
    @Published private(set) var isBusy = false

    private let healthStore = HKHealthStore()

    func requestAuthorization() async {
        guard isAvailable else {
            authorizationResult = "Health data is unavailable"
            AppLog.health.error("\(AppLog.stamp(), privacy: .public) HealthKit is unavailable")
            return
        }

        let workout = HKWorkoutType.workoutType()
        guard
            let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
            let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate)
        else {
            authorizationResult = "Required HealthKit types are unavailable"
            AppLog.health.error("\(AppLog.stamp(), privacy: .public) Could not create required HealthKit types")
            return
        }

        let shareTypes: Set<HKSampleType> = [workout, activeEnergy, distance]
        let readTypes: Set<HKObjectType> = [workout, heartRate, activeEnergy, distance]

        isBusy = true
        defer { isBusy = false }
        AppLog.health.info("\(AppLog.stamp(), privacy: .public) Requesting HealthKit authorization")

        do {
            try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
            let status = healthStore.authorizationStatus(for: workout)
            authorizationResult = "Request completed; workout share status: \(description(for: status))"
            AppLog.health.info("\(AppLog.stamp(), privacy: .public) Authorization request completed; workout share status=\(status.rawValue)")

            // HealthKit deliberately makes read-denied indistinguishable from read-granted.
            // Therefore authorizationStatus(for:) is only meaningful for share types.
            AppLog.health.info("\(AppLog.stamp(), privacy: .public) Read authorization is intentionally not inferred from authorizationStatus")
        } catch {
            authorizationResult = "Authorization failed: \(error.localizedDescription)"
            AppLog.health.error("\(AppLog.stamp(), privacy: .public) Authorization failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func writeAndReadBackSample() async -> String {
        guard isAvailable else {
            let result = "Health data is unavailable"
            roundTripResult = result
            AppLog.health.error("\(AppLog.stamp(), privacy: .public) E1.0 cannot run: HealthKit is unavailable")
            return result
        }

        guard let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            let result = "Active energy type is unavailable"
            roundTripResult = result
            AppLog.health.error("\(AppLog.stamp(), privacy: .public) E1.0 cannot create active-energy type")
            return result
        }

        isBusy = true
        defer { isBusy = false }

        let now = Date()
        let sample = HKQuantitySample(
            type: activeEnergy,
            quantity: HKQuantity(unit: .kilocalorie(), doubleValue: 1),
            start: now,
            end: now
        )
        AppLog.health.info("\(AppLog.stamp(), privacy: .public) E1.0 saving 1 kcal sample UUID=\(sample.uuid.uuidString, privacy: .public)")

        do {
            try await healthStore.save(sample)
            AppLog.health.info("\(AppLog.stamp(), privacy: .public) E1.0 save completed UUID=\(sample.uuid.uuidString, privacy: .public)")

            let readSample = try await readSample(uuid: sample.uuid, type: activeEnergy)
            let result: String
            if let readSample, readSample.uuid == sample.uuid {
                result = "PASS: wrote and read back sample UUID \(readSample.uuid.uuidString)"
                AppLog.health.info("\(AppLog.stamp(), privacy: .public) E1.0 round trip succeeded UUID=\(readSample.uuid.uuidString, privacy: .public)")
            } else {
                result = "FAIL: write succeeded, but UUID \(sample.uuid.uuidString) was not returned by the read query"
                AppLog.health.error("\(AppLog.stamp(), privacy: .public) E1.0 read query did not return UUID=\(sample.uuid.uuidString, privacy: .public)")
            }
            roundTripResult = result
            return result
        } catch {
            let result = "FAIL: round trip error for UUID \(sample.uuid.uuidString): \(error.localizedDescription)"
            roundTripResult = result
            AppLog.health.error("\(AppLog.stamp(), privacy: .public) E1.0 failed UUID=\(sample.uuid.uuidString, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return result
        }
    }

    // Reading samples written by this app proves only self-read, not that HealthKit granted read access.
    func readForeignSamples() async -> String {
        guard isAvailable else {
            let result = "Health data is unavailable"
            foreignReadResult = result
            AppLog.health.error("\(AppLog.stamp(), privacy: .public) E1.0b cannot run: HealthKit is unavailable")
            return result
        }

        guard let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            let result = "Heart rate type is unavailable"
            foreignReadResult = result
            AppLog.health.error("\(AppLog.stamp(), privacy: .public) E1.0b cannot create heart-rate type")
            return result
        }

        isBusy = true
        defer { isBusy = false }
        AppLog.health.info("\(AppLog.stamp(), privacy: .public) E1.0b starting foreign-data probe")

        do {
            let heartRateSamples = try await readForeignSamples(
                type: heartRate,
                limit: 10,
                label: "heart rate"
            )
            let workoutSamples = try await readForeignSamples(
                type: HKWorkoutType.workoutType(),
                limit: 5,
                label: "workout"
            )

            let result = [
                summary(label: "Heart rate", samples: heartRateSamples),
                summary(label: "Workouts", samples: workoutSamples),
                interpretation(hasForeignSamples: !heartRateSamples.isEmpty || !workoutSamples.isEmpty)
            ].joined(separator: "\n")
            foreignReadResult = result
            AppLog.health.info("\(AppLog.stamp(), privacy: .public) E1.0b foreign-data probe completed: \(result, privacy: .public)")
            return result
        } catch {
            let result = "Foreign-data probe failed: \(error.localizedDescription)"
            foreignReadResult = result
            AppLog.health.error("\(AppLog.stamp(), privacy: .public) E1.0b failed: \(error.localizedDescription, privacy: .public)")
            return result
        }
    }

    private func readForeignSamples(type: HKSampleType, limit: Int, label: String) async throws -> [HKSample] {
        AppLog.health.info("\(AppLog.stamp(), privacy: .public) E1.0b querying \(label, privacy: .public) samples limit=\(limit)")
        let samples: [HKSample] = try await withCheckedThrowingContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: limit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples ?? [])
                }
            }
            healthStore.execute(query)
        }

        let appSource = HKSource.default()
        let foreignSamples = samples.filter { $0.sourceRevision.source != appSource }
        AppLog.health.info("\(AppLog.stamp(), privacy: .public) E1.0b \(label, privacy: .public) query returned \(samples.count) total, \(foreignSamples.count) foreign")
        return foreignSamples
    }

    private func summary(label: String, samples: [HKSample]) -> String {
        let sourceNames = Set(samples.map { $0.sourceRevision.source.name }).sorted()
        let sources = sourceNames.isEmpty ? "none" : sourceNames.joined(separator: ", ")
        let mostRecent = samples.first.map { $0.startDate.formatted(date: .abbreviated, time: .shortened) } ?? "none"
        return "\(label): \(samples.count) foreign samples\nSources: \(sources)\nMost recent: \(mostRecent)"
    }

    private func interpretation(hasForeignSamples: Bool) -> String {
        if hasForeignSamples {
            return "CONFIRMED: Read access is confirmed because data written by another source was successfully read."
        }
        return "INCONCLUSIVE: No foreign samples were found. HealthKit makes read-denied indistinguishable from no data present, so this cannot distinguish permission denied from no such data on this device."
    }

    private func readSample(uuid: UUID, type: HKSampleType) async throws -> HKSample? {
        AppLog.health.info("\(AppLog.stamp(), privacy: .public) E1.0 querying UUID=\(uuid.uuidString, privacy: .public)")
        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForObject(with: uuid)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples?.first)
                }
            }
            healthStore.execute(query)
        }
    }

    private func description(for status: HKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "not determined"
        case .sharingDenied: return "sharing denied"
        case .sharingAuthorized: return "sharing authorized"
        @unknown default: return "unknown (\(status.rawValue))"
        }
    }
}
