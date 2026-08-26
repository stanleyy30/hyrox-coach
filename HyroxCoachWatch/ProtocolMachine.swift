// E2.2: shortened semantic protocol with persist-on-transition.

import Foundation
import Combine
import OSLog

@MainActor
final class ProtocolMachine: ObservableObject {
    @Published private(set) var report = ""
    @Published private(set) var restoreReport = "Checking persisted state…"
    @Published private(set) var diskReport = "Disk not inspected yet."
    @Published private(set) var reconciliationReport = "Records not compared yet."

    private var store: StateStore
    private var state: WorkoutState
    private var timer: Timer?
    private var lastError: String?

    init(store: StateStore = StateStore()) {
        self.store = store
        let now = Date()
        state = WorkoutState(
            sessionID: UUID(),
            protocolStartedAt: now,
            kind: .idle,
            stateStartedAt: now
        )
        restoreOnLaunch()
        refreshDiskReport()
        refreshReport()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshReport()
            }
        }
    }

    var crashPoint: StateStore.CrashPoint {
        get { store.crashPoint }
        set { store.crashPoint = newValue }
    }

    var completedSegmentCount: Int {
        state.completedSegments.count
    }

    func healthKitSegmentsCharacterCount(sessionStart: Date) -> Int {
        healthKitSegments(sessionStart: sessionStart).count
    }

    func healthKitMetadata(sessionStart: Date) -> [String: String] {
        guard !state.completedSegments.isEmpty else {
            AppLog.workout.info("\(AppLog.stamp(), privacy: .public) HYROX metadata omitted: no completed segments")
            return [:]
        }

        let locale = Locale(identifier: "en_US_POSIX")
        let segments = healthKitSegments(sessionStart: sessionStart)
        let protocolStartOffset = state.protocolStartedAt.timeIntervalSince(sessionStart)

        // HealthKit metadata accepts property-list values. Keep this payload flat
        // and string-only so its values cannot be changed through type coercion.
        return [
            "HYROXSchemaVersion": "1",
            "HYROXSegmentCount": String(state.completedSegments.count),
            "HYROXSegments": segments,
            // Declaring the sent character count exposes silent truncation downstream.
            "HYROXSegmentsLength": String(segments.count),
            "HYROXProtocolStartOffset": String(
                format: "%.3f",
                locale: locale,
                protocolStartOffset
            )
        ]
    }

    // Experiment affordance: this creates seeded test data, not a real workout.
    func seedFullRace() {
        let stationNames = [
            "SkiErg",
            "Sled Push",
            "Sled Pull",
            "Burpee Broad Jumps",
            "Rowing",
            "Farmers Carry",
            "Sandbag Lunges",
            "Wall Balls"
        ]
        let runDurations: [TimeInterval] = [375, 370, 380, 385, 390, 395, 400, 405]
        let roxzoneDurations: [TimeInterval] = [40, 42, 45, 43, 46, 44, 48, 47]
        let stationDurations: [TimeInterval] = [240, 270, 240, 270, 240, 240, 270, 210]

        var startedAt = state.protocolStartedAt
        var segments: [WorkoutState.CompletedSegment] = []

        func appendSegment(
            kind: WorkoutState.SegmentKind,
            identity: WorkoutState.SegmentIdentity,
            duration: TimeInterval
        ) {
            let endedAt = startedAt.addingTimeInterval(duration)
            segments.append(
                WorkoutState.CompletedSegment(
                    kind: kind,
                    identity: identity,
                    startedAt: startedAt,
                    endedAt: endedAt
                )
            )
            startedAt = endedAt
        }

        appendSegment(kind: .preparing, identity: .preparation, duration: 60)
        for index in stationNames.indices {
            let number = index + 1
            appendSegment(
                kind: .running,
                identity: .leg(number),
                duration: runDurations[index]
            )
            appendSegment(
                kind: .roxzone,
                identity: .leg(number),
                duration: roxzoneDurations[index]
            )
            appendSegment(
                kind: .station,
                identity: .station(index: number, name: stationNames[index]),
                duration: stationDurations[index]
            )
        }

        let seededState = WorkoutState(
            sessionID: state.sessionID,
            protocolStartedAt: state.protocolStartedAt,
            healthKitSessionStartDate: state.healthKitSessionStartDate,
            healthKitSessionUUID: state.healthKitSessionUUID,
            kind: .completed,
            stateStartedAt: startedAt,
            completedSegments: segments
        )

        do {
            try store.save(seededState)
            state = seededState
            lastError = nil
            refreshReport()
            AppLog.lifecycle.info("\(AppLog.stamp(), privacy: .public) E4.0 seeded test data, not a real workout: full race segments=\(segments.count, privacy: .public)")
        } catch {
            record(error, operation: "seed full race")
        }
    }

    func start() {
        let now = Date()
        let freshState = WorkoutState(
            sessionID: UUID(),
            protocolStartedAt: now,
            kind: .preparing,
            stateStartedAt: now
        )
        commit(freshState, operation: "start")
    }

    func advance() {
        guard let nextKind = nextKind(after: state.kind) else {
            lastError = "Advance is unavailable from \(Self.kindDescription(state.kind))."
            refreshReport()
            return
        }

        let now = Date()
        guard let closedSegment = completedSegment(for: state, endedAt: now) else {
            lastError = "The current state has no closable segment."
            refreshReport()
            return
        }

        let history = Array(
            (state.undoHistory + [state.snapshot])
                .suffix(WorkoutState.maximumUndoHistoryCount)
        )
        let nextState = WorkoutState(
            sessionID: state.sessionID,
            protocolStartedAt: state.protocolStartedAt,
            healthKitSessionStartDate: state.healthKitSessionStartDate,
            healthKitSessionUUID: state.healthKitSessionUUID,
            kind: nextKind,
            stateStartedAt: now,
            completedSegments: state.completedSegments + [closedSegment],
            undoHistory: history
        )
        commit(nextState, operation: "advance")
    }

    func undo() {
        guard let snapshot = state.undoHistory.last else {
            lastError = "Nothing to undo."
            refreshReport()
            return
        }

        let restoredState = WorkoutState(
            sessionID: state.sessionID,
            protocolStartedAt: state.protocolStartedAt,
            healthKitSessionStartDate: state.healthKitSessionStartDate,
            healthKitSessionUUID: state.healthKitSessionUUID,
            kind: snapshot.kind,
            stateStartedAt: snapshot.stateStartedAt,
            completedSegments: snapshot.completedSegments,
            undoHistory: Array(state.undoHistory.dropLast())
        )
        commit(restoredState, operation: "undo")
    }

    func reset() {
        do {
            try store.clear()
            let now = Date()
            state = WorkoutState(
                sessionID: UUID(),
                protocolStartedAt: now,
                kind: .idle,
                stateStartedAt: now
            )
            lastError = nil
            refreshReport()
        } catch {
            record(error, operation: "reset")
        }
    }

    func refreshDiskReport() {
        diskReport = store.inspect()
    }

    func attachHealthKitSession(startDate: Date, uuid: String) {
        let attachedState = WorkoutState(
            sessionID: state.sessionID,
            protocolStartedAt: state.protocolStartedAt,
            healthKitSessionStartDate: startDate,
            healthKitSessionUUID: uuid,
            kind: state.kind,
            stateStartedAt: state.stateStartedAt,
            completedSegments: state.completedSegments,
            undoHistory: state.undoHistory
        )

        do {
            try store.save(attachedState)
            state = attachedState
            lastError = nil
            refreshReport()
            refreshReconciliation()
            AppLog.workout.info("\(AppLog.stamp(), privacy: .public) E2.3 attached HK session UUID=\(uuid, privacy: .public) startDate=\(startDate.description, privacy: .public)")
        } catch {
            lastError = "Attach HealthKit session failed: \(error.localizedDescription)"
            AppLog.workout.error("\(AppLog.stamp(), privacy: .public) E2.3 attach failed: \(error.localizedDescription, privacy: .public)")
            refreshReport()
        }
    }

    func refreshReconciliation() {
        var lines = [
            "Semantic protocolStartedAt: \(Self.reconciliationDateFormatter.string(from: state.protocolStartedAt))"
        ]

        guard let healthKitStartDate = state.healthKitSessionStartDate else {
            lines.append("HealthKit session: no session is attached")
            lines.append("Delta (semantic − HealthKit): unavailable")
            lines.append("ROUND-TRIP: unavailable until a HealthKit session is attached")
            reconciliationReport = lines.joined(separator: "\n")
            return
        }

        lines.append("HealthKit startDate: \(Self.reconciliationDateFormatter.string(from: healthKitStartDate))")
        if let uuid = state.healthKitSessionUUID {
            lines.append("HealthKit UUID: \(uuid)")
        } else {
            lines.append("HealthKit UUID: unavailable")
        }

        let startDeltaMilliseconds = state.protocolStartedAt
            .timeIntervalSince(healthKitStartDate) * 1_000
        lines.append(
            "Delta (semantic − HealthKit): \(String(format: "%+.3f", startDeltaMilliseconds)) ms"
        )

        var worstRoundTripMilliseconds = 0.0
        for (index, segment) in state.completedSegments.enumerated() {
            let offset = segment.startedAt.timeIntervalSince(healthKitStartDate)
            let recomputedDate = healthKitStartDate.addingTimeInterval(offset)
            let roundTripMilliseconds = abs(
                recomputedDate.timeIntervalSince(segment.startedAt) * 1_000
            )
            worstRoundTripMilliseconds = max(
                worstRoundTripMilliseconds,
                roundTripMilliseconds
            )
            lines.append(
                "\(index + 1). \(Self.segmentDescription(segment)): startedAt \(Self.reconciliationDateFormatter.string(from: segment.startedAt)); offset \(String(format: "%+.6f", offset)) s; recomputed \(Self.reconciliationDateFormatter.string(from: recomputedDate))"
            )
        }

        if worstRoundTripMilliseconds <= 1 {
            lines.append("ROUND-TRIP: EXACT")
        } else {
            lines.append(
                "ROUND-TRIP: DRIFT (worst \(String(format: "%.3f", worstRoundTripMilliseconds)) ms)"
            )
        }
        reconciliationReport = lines.joined(separator: "\n")
    }

    func cleanUpTempFiles() {
        do {
            try store.cleanUpTempFiles()
            refreshDiskReport()
        } catch {
            diskReport = "Temp-file cleanup failed: \(error.localizedDescription)\n\(store.inspect())"
            AppLog.lifecycle.error("\(AppLog.stamp(), privacy: .public) E2.2b temp-file cleanup failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func restoreOnLaunch() {
        let crashDescription = consumeLastCrashDescription()

        do {
            guard let restoredState = try store.load() else {
                restoreReport = [
                    "No persisted state to restore.",
                    crashDescription
                ].compactMap { $0 }.joined(separator: "\n")
                AppLog.lifecycle.info("\(AppLog.stamp(), privacy: .public) E2.2 no persisted state found")
                return
            }

            state = restoredState
            let age = Date().timeIntervalSince(restoredState.stateStartedAt)
            restoreReport = [
                "Restored \(Self.kindDescription(restoredState.kind)); state began \(Self.durationDescription(age)) ago; \(restoredState.completedSegments.count) segments complete.",
                crashDescription
            ].compactMap { $0 }.joined(separator: "\n")
            AppLog.lifecycle.info("\(AppLog.stamp(), privacy: .public) E2.2 restored kind=\(String(describing: restoredState.kind), privacy: .public) stateAge=\(age, privacy: .public) segments=\(restoredState.completedSegments.count, privacy: .public)")
        } catch let StateStore.StoreError.unsupportedSchema(found, expected) {
            let message = "Version mismatch: persisted workout state schema \(found); expected \(expected)."
            restoreReport = [message, crashDescription]
                .compactMap { $0 }
                .joined(separator: "\n")
            lastError = message
            AppLog.lifecycle.error("\(AppLog.stamp(), privacy: .public) E2.2 state load version mismatch found=\(found, privacy: .public) expected=\(expected, privacy: .public)")
        } catch {
            let message = "Load failed: \(error.localizedDescription)"
            restoreReport = [message, crashDescription]
                .compactMap { $0 }
                .joined(separator: "\n")
            lastError = message
            AppLog.lifecycle.error("\(AppLog.stamp(), privacy: .public) E2.2 state load failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func consumeLastCrashDescription() -> String? {
        let defaults = UserDefaults.standard
        guard let rawPoint = defaults.string(forKey: "e22b.lastCrashPoint") else {
            return nil
        }
        let date = defaults.object(forKey: "e22b.lastCrashDate") as? Date
        defaults.removeObject(forKey: "e22b.lastCrashPoint")
        defaults.removeObject(forKey: "e22b.lastCrashDate")

        if let date {
            return "Last crash point: \(rawPoint) at \(Self.crashDateFormatter.string(from: date))."
        }
        return "Last crash point: \(rawPoint)."
    }

    private func commit(_ candidate: WorkoutState, operation: String) {
        do {
            try store.save(candidate)
            state = candidate
            lastError = nil
            refreshReport()
        } catch {
            record(error, operation: operation)
        }
    }

    private func record(_ error: Error, operation: String) {
        lastError = "\(operation.capitalized) failed: \(error.localizedDescription)"
        AppLog.lifecycle.error("\(AppLog.stamp(), privacy: .public) E2.2 \(operation, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
        refreshReport()
    }

    private func refreshReport() {
        let elapsed = Date().timeIntervalSince(state.stateStartedAt)
        var lines = [
            "Current: \(Self.kindDescription(state.kind))",
            "Current elapsed: \(Self.durationDescription(elapsed))",
            "Completed segments: \(state.completedSegments.count)"
        ]

        for (offset, segment) in state.completedSegments.enumerated() {
            let duration = segment.endedAt.timeIntervalSince(segment.startedAt)
            lines.append("\(offset + 1). \(Self.segmentDescription(segment)): \(Self.durationDescription(duration))")
        }
        if let lastError {
            lines.append("Error: \(lastError)")
        }
        report = lines.joined(separator: "\n")
    }

    private func nextKind(after kind: WorkoutState.Kind) -> WorkoutState.Kind? {
        switch kind {
        case .idle, .completed:
            return nil
        case .preparing:
            return .running(leg: 1)
        case .running(leg: 1):
            return .inRoxzone(leg: 1)
        case .inRoxzone(leg: 1):
            return .inStation(index: 1, name: "SkiErg")
        case .inStation(index: 1, name: _):
            return .running(leg: 2)
        case .running(leg: 2):
            return .inRoxzone(leg: 2)
        case .inRoxzone(leg: 2):
            return .inStation(index: 2, name: "Sled Push")
        case .inStation(index: 2, name: _):
            return .completed
        case .running, .inRoxzone, .inStation:
            return nil
        }
    }

    private func completedSegment(
        for state: WorkoutState,
        endedAt: Date
    ) -> WorkoutState.CompletedSegment? {
        let kind: WorkoutState.SegmentKind
        let identity: WorkoutState.SegmentIdentity

        switch state.kind {
        case .idle, .completed:
            return nil
        case .preparing:
            kind = .preparing
            identity = .preparation
        case let .running(leg):
            kind = .running
            identity = .leg(leg)
        case let .inRoxzone(leg):
            kind = .roxzone
            identity = .leg(leg)
        case let .inStation(index, name):
            kind = .station
            identity = .station(index: index, name: name)
        }

        return WorkoutState.CompletedSegment(
            kind: kind,
            identity: identity,
            startedAt: state.stateStartedAt,
            endedAt: endedAt
        )
    }

    private func healthKitSegments(sessionStart: Date) -> String {
        let locale = Locale(identifier: "en_US_POSIX")
        return state.completedSegments.map { segment in
            let offset = segment.startedAt.timeIntervalSince(sessionStart)
            return "\(Self.segmentDescription(segment))@\(String(format: "%.3f", locale: locale, offset))"
        }.joined(separator: ";")
    }

    private static func kindDescription(_ kind: WorkoutState.Kind) -> String {
        switch kind {
        case .idle:
            return "Idle"
        case .preparing:
            return "Preparing"
        case let .running(leg):
            return "Run \(leg)"
        case let .inRoxzone(leg):
            return "Roxzone \(leg)"
        case let .inStation(index, name):
            return "Station \(index) — \(name)"
        case .completed:
            return "Completed"
        }
    }

    private static func segmentDescription(_ segment: WorkoutState.CompletedSegment) -> String {
        switch segment.identity {
        case .preparation:
            return "Preparing"
        case let .leg(number):
            return segment.kind == .running ? "Run \(number)" : "Roxzone \(number)"
        case let .station(index, name):
            return "Station \(index) — \(name)"
        }
    }

    private static func durationDescription(_ interval: TimeInterval) -> String {
        let sign = interval < 0 ? "−" : ""
        let magnitude = abs(interval)
        if magnitude < 60 {
            return "\(sign)\(String(format: "%.1f", magnitude))s"
        }

        let totalSeconds = Int(magnitude.rounded())
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return "\(sign)\(hours)h \(minutes)m \(seconds)s"
        }
        return "\(sign)\(minutes)m \(seconds)s"
    }

    private static let crashDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d HH:mm:ss"
        return formatter
    }()

    private static let reconciliationDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
