// WorkoutHistory.swift
// Reads recent workouts on iPhone so HealthKit delivery from Apple Watch can be observed.

import Combine
import Foundation
import HealthKit

struct WorkoutEventRecord: Identifiable {
    let id: Int
    let typeName: String
    let startOffset: TimeInterval
    let duration: TimeInterval
    let metadata: [String: String]
}

struct WorkoutRow: Identifiable {
    let uuid: UUID
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let activityTypeName: String
    let sourceName: String
    let deviceName: String
    let totalActiveEnergyKilocalories: Double?
    let metadata: [String: String]
    let events: [WorkoutEventRecord]

    var id: UUID { uuid }

    var eventSummary: String {
        guard !events.isEmpty else { return "NO EVENTS" }

        let counts = Dictionary(grouping: events, by: \.typeName)
            .mapValues(\.count)
        let breakdown = counts
            .sorted { first, second in
                if first.value == second.value {
                    return first.key < second.key
                }
                return first.value > second.value
            }
            .map { "\($0.value) \($0.key)" }
            .joined(separator: ", ")
        let eventWord = events.count == 1 ? "EVENT" : "EVENTS"
        return "\(events.count) \(eventWord) · \(breakdown)"
    }

    var hasHyroxMetadata: Bool {
        metadata.keys.contains { $0.hasPrefix("HYROX") }
    }

    var hyroxReceivedSegmentLength: Int? {
        metadata["HYROXSegments"]?.count
    }

    var segmentSourceAgreement: String {
        let segmentEvents = events.filter { event in
            event.typeName == "segment" && event.metadata["HYROXSegmentName"] != nil
        }
        let segmentString = metadata["HYROXSegments"]

        if segmentString == nil && segmentEvents.isEmpty {
            return "NEITHER — no HYROX segment string or events"
        }
        if segmentString == nil {
            return "EVENTS ONLY — \(segmentEvents.count) segment event(s)"
        }

        guard let segmentString else {
            return "DISAGREE — HYROXSegments could not be read"
        }

        switch Self.parseSegments(from: segmentString) {
        case let .failure(reason):
            return "DISAGREE — \(reason.reason)"
        case let .success(stringSegments):
            if segmentEvents.isEmpty {
                return "STRING ONLY — \(stringSegments.count) string entr\(stringSegments.count == 1 ? "y" : "ies")"
            }

            guard stringSegments.count == segmentEvents.count else {
                return "DISAGREE — counts: string \(stringSegments.count), events \(segmentEvents.count)"
            }

            for (index, pair) in zip(stringSegments, segmentEvents).enumerated() {
                let position = index + 1
                let stringSegment = pair.0
                let event = pair.1

                let eventName = event.metadata["HYROXSegmentName"] ?? ""

                guard eventName == stringSegment.name else {
                    return "DISAGREE — index \(position) names: string “\(stringSegment.name)”, events “\(eventName)”"
                }

                guard event.startOffset.isFinite else {
                    return "DISAGREE — event offset at index \(position) could not be parsed as a finite number"
                }

                let difference = abs(stringSegment.offset - event.startOffset)
                guard difference <= 0.05 else {
                    return String(
                        format: "DISAGREE — index %d offsets: string %.3f seconds, events %.3f seconds; difference %.3f seconds",
                        position,
                        stringSegment.offset,
                        event.startOffset,
                        difference
                    )
                }
            }

            return "AGREE — \(stringSegments.count) segment(s)"
        }
    }

    var hyroxFirstAndLastOffsets: String? {
        guard hasHyroxMetadata else { return nil }
        guard let segments = metadata["HYROXSegments"], !segments.isEmpty else {
            return "Not available"
        }

        let entries = segments.split(
            separator: ";",
            omittingEmptySubsequences: false
        )
        let first = entries.first.map { Self.rawOffsetText(from: $0) } ?? "Not available"
        let last = entries.last.map { Self.rawOffsetText(from: $0) } ?? "Not available"
        return "first: \(first); last: \(last)"
    }

    var hyroxIntegrity: String {
        guard hasHyroxMetadata else {
            return "NO HYROX METADATA"
        }

        guard let segments = metadata["HYROXSegments"],
              let declaredLengthText = metadata["HYROXSegmentsLength"],
              let declaredCountText = metadata["HYROXSegmentCount"],
              let declaredLength = Int(declaredLengthText),
              let declaredCount = Int(declaredCountText),
              declaredLength >= 0,
              declaredCount >= 0 else {
            return "INCOMPLETE CONTRACT"
        }

        let receivedLength = segments.count
        let receivedCount = segments.isEmpty
            ? 0
            : segments.split(separator: ";").count

        let numbers = "length received \(receivedLength) vs declared \(declaredLength); count received \(receivedCount) vs declared \(declaredCount)"

        guard receivedLength == declaredLength && receivedCount == declaredCount else {
            if receivedLength <= declaredLength && receivedCount <= declaredCount {
                return "TRUNCATED — \(numbers)"
            }

            return "MISMATCH — \(numbers)"
        }

        guard let offsets = Self.parseOffsets(from: segments) else {
            return "INCOMPLETE CONTRACT"
        }

        for (index, offset) in offsets.enumerated() where offset.value < 0 {
            let position = index == 0 ? "first offset" : "offset \(index + 1)"
            return "IMPLAUSIBLE: \(position) \(offset.text) is negative"
        }

        for index in offsets.indices.dropFirst() {
            let previousIndex = offsets.index(before: index)
            let previous = offsets[previousIndex]
            let current = offsets[index]

            if current.value <= previous.value {
                return "IMPLAUSIBLE: offset \(index + 1) (\(current.text)) is not greater than offset \(previousIndex + 1) (\(previous.text))"
            }
        }

        if let finalOffset = offsets.last,
           finalOffset.value > duration + 60 {
            return "IMPLAUSIBLE: final offset \(finalOffset.text) exceeds workout duration \(duration) by more than 60 seconds"
        }

        return "INTACT"
    }

    private static func parseOffsets(from segments: String) -> [(value: Double, text: String)]? {
        guard !segments.isEmpty else { return [] }

        var offsets: [(value: Double, text: String)] = []
        for entry in segments.split(separator: ";", omittingEmptySubsequences: false) {
            let parts = entry.split(
                separator: "@",
                maxSplits: 1,
                omittingEmptySubsequences: false
            )
            guard parts.count == 2,
                  !parts[0].isEmpty,
                  !parts[1].isEmpty,
                  let value = Double(parts[1]),
                  value.isFinite else {
                return nil
            }

            offsets.append((value: value, text: String(parts[1])))
        }
        return offsets
    }

    private static func parseSegments(
        from segments: String
    ) -> Result<[(name: String, offset: Double)], SegmentParseError> {
        guard !segments.isEmpty else { return .success([]) }

        var parsedSegments: [(name: String, offset: Double)] = []
        for (index, entry) in segments.split(
            separator: ";",
            omittingEmptySubsequences: false
        ).enumerated() {
            let position = index + 1
            let parts = entry.split(
                separator: "@",
                maxSplits: 1,
                omittingEmptySubsequences: false
            )

            guard parts.count == 2 else {
                return .failure(
                    SegmentParseError(
                        reason: "string entry at index \(position) could not be parsed as name@offset"
                    )
                )
            }
            guard !parts[0].isEmpty else {
                return .failure(
                    SegmentParseError(reason: "string name at index \(position) is empty")
                )
            }
            guard !parts[1].isEmpty,
                  let offset = Double(parts[1]),
                  offset.isFinite else {
                return .failure(
                    SegmentParseError(
                        reason: "string offset at index \(position) could not be parsed as a finite number: “\(parts[1])”"
                    )
                )
            }

            parsedSegments.append((name: String(parts[0]), offset: offset))
        }
        return .success(parsedSegments)
    }

    private static func rawOffsetText(from entry: Substring) -> String {
        let parts = entry.split(
            separator: "@",
            maxSplits: 1,
            omittingEmptySubsequences: false
        )
        guard parts.count == 2, !parts[1].isEmpty else {
            return "Not available"
        }
        return String(parts[1])
    }

    var hyroxIntegrityMarker: String? {
        guard hasHyroxMetadata else { return nil }

        if hyroxIntegrity.hasPrefix("TRUNCATED") {
            return "TRUNCATED"
        }
        if hyroxIntegrity.hasPrefix("MISMATCH") {
            return "MISMATCH"
        }
        return hyroxIntegrity
    }
}

struct HeartRateSummary {
    let sampleCount: Int
    let minimum: Double?
    let maximum: Double?
    let average: Double?
    let status: String
}

@MainActor
final class WorkoutHistory: ObservableObject {
    @Published private(set) var rows: [WorkoutRow] = []
    @Published private(set) var lastRefreshed: Date?
    @Published private(set) var statusLine = "Not refreshed yet."
    @Published private(set) var mostRecentTimeSinceEnded: String?
    @Published private(set) var isLoading = false

    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    func refresh() async {
        guard !isLoading else { return }

        isLoading = true
        statusLine = "Querying HealthKit workouts…"
        defer { isLoading = false }

        do {
            let workouts = try await queryWorkouts()
            let queryTime = Date()
            let newRows = workouts.map(Self.makeRow)

            rows = newRows
            lastRefreshed = queryTime

            // This is time between the workout ending and this query. It is only the
            // HealthKit sync delay if the query is made at the instant the workout arrives.
            if let newestWorkout = workouts.first {
                let interval = queryTime.timeIntervalSince(newestWorkout.endDate)
                mostRecentTimeSinceEnded = Self.readableTimeSinceEnd(interval)
            } else {
                mostRecentTimeSinceEnded = nil
            }

            if newRows.isEmpty {
                statusLine = "Query succeeded: no workouts found."
            } else {
                statusLine = "Query succeeded: \(newRows.count) workout(s) found."
            }

            AppLog.health.info(
                "[\(AppLog.stamp(), privacy: .public)] Workout refresh completed; count returned: \(newRows.count, privacy: .public)"
            )
        } catch {
            rows = []
            lastRefreshed = Date()
            mostRecentTimeSinceEnded = nil
            statusLine = "Workout query failed: \(error.localizedDescription)"

            AppLog.health.error(
                "[\(AppLog.stamp(), privacy: .public)] Workout refresh failed; count returned: unavailable; error: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    func heartRate(for workoutUUID: UUID) async -> HeartRateSummary {
        do {
            let workout = try await queryWorkout(with: workoutUUID)
            let samples = try await queryHeartRateSamples(for: workout)
            let beatsPerMinute = HKUnit.count().unitDivided(by: .minute())
            let values = samples.map { sample in
                sample.quantity.doubleValue(for: beatsPerMinute)
            }
            let sampleCount = values.count

            let summary = HeartRateSummary(
                sampleCount: sampleCount,
                minimum: values.min(),
                maximum: values.max(),
                average: values.isEmpty
                    ? nil
                    : values.reduce(0, +) / Double(sampleCount),
                status: values.isEmpty ? "NO SAMPLES" : "\(sampleCount) SAMPLES"
            )

            AppLog.health.info(
                "[\(AppLog.stamp(), privacy: .public)] Heart-rate query completed; workout: \(workoutUUID.uuidString, privacy: .public); sample count: \(sampleCount, privacy: .public); status: \(summary.status, privacy: .public)"
            )
            return summary
        } catch {
            let summary = HeartRateSummary(
                sampleCount: 0,
                minimum: nil,
                maximum: nil,
                average: nil,
                status: "QUERY FAILED — \(error.localizedDescription)"
            )

            AppLog.health.error(
                "[\(AppLog.stamp(), privacy: .public)] Heart-rate query failed; workout: \(workoutUUID.uuidString, privacy: .public); sample count: \(summary.sampleCount, privacy: .public); status: \(summary.status, privacy: .public)"
            )
            return summary
        }
    }

    private func queryWorkouts() async throws -> [HKWorkout] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKWorkoutType.workoutType(),
                predicate: nil,
                limit: 20,
                sortDescriptors: [
                    NSSortDescriptor(
                        key: HKSampleSortIdentifierStartDate,
                        ascending: false
                    )
                ]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: samples?.compactMap { $0 as? HKWorkout } ?? [])
            }

            healthStore.execute(query)
        }
    }

    private func queryWorkout(with uuid: UUID) async throws -> HKWorkout {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKWorkoutType.workoutType(),
                predicate: HKQuery.predicateForObject(with: uuid),
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let workout = samples?.first as? HKWorkout else {
                    continuation.resume(throwing: HeartRateQueryError.workoutNotFound(uuid))
                    return
                }

                continuation.resume(returning: workout)
            }

            healthStore.execute(query)
        }
    }

    private func queryHeartRateSamples(for workout: HKWorkout) async throws -> [HKQuantitySample] {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HeartRateQueryError.heartRateTypeUnavailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: HKQuery.predicateForObjects(from: workout),
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(
                    returning: samples?.compactMap { $0 as? HKQuantitySample } ?? []
                )
            }

            healthStore.execute(query)
        }
    }

    private static func makeRow(from workout: HKWorkout) -> WorkoutRow {
        let deviceName = workout.device?.name
            ?? workout.sourceRevision.productType
            ?? "unknown"
        let events = (workout.workoutEvents ?? [])
            .enumerated()
            .map { index, event in
                WorkoutEventRecord(
                    id: index,
                    typeName: workoutEventTypeName(for: event.type),
                    startOffset: event.dateInterval.start.timeIntervalSince(workout.startDate),
                    duration: event.dateInterval.duration,
                    metadata: Dictionary(
                        uniqueKeysWithValues: (event.metadata ?? [:]).map { key, value in
                            (key, readableMetadataValue(value))
                        }
                    )
                )
            }
            .sorted { first, second in
                if first.startOffset == second.startOffset {
                    return first.id < second.id
                }
                return first.startOffset < second.startOffset
            }

        let row = WorkoutRow(
            uuid: workout.uuid,
            startDate: workout.startDate,
            endDate: workout.endDate,
            duration: workout.duration,
            activityTypeName: activityTypeName(for: workout.workoutActivityType),
            sourceName: workout.sourceRevision.source.name,
            deviceName: deviceName,
            totalActiveEnergyKilocalories: workout.totalEnergyBurned?.doubleValue(
                for: .kilocalorie()
            ),
            metadata: Dictionary(
                uniqueKeysWithValues: (workout.metadata ?? [:]).map { key, value in
                    (key, readableMetadataValue(value))
                }
            ),
            events: events
        )

        AppLog.health.info(
            "[\(AppLog.stamp(), privacy: .public)] HYROX metadata integrity; workout: \(row.uuid.uuidString, privacy: .public); verdict: \(row.hyroxIntegrity, privacy: .public)"
        )
        AppLog.health.info(
            "[\(AppLog.stamp(), privacy: .public)] Workout events; workout: \(row.uuid.uuidString, privacy: .public); count and types: \(row.eventSummary, privacy: .public)"
        )
        AppLog.health.info(
            "[\(AppLog.stamp(), privacy: .public)] Segment source agreement; workout: \(row.uuid.uuidString, privacy: .public); verdict: \(row.segmentSourceAgreement, privacy: .public)"
        )

        return row
    }

    private static func readableMetadataValue(_ value: Any) -> String {
        if let date = value as? Date {
            return date.formatted(date: .abbreviated, time: .standard)
        }

        if let data = value as? Data {
            return data.base64EncodedString()
        }

        if JSONSerialization.isValidJSONObject(value),
           let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]),
           let string = String(data: data, encoding: .utf8) {
            return string
        }

        return String(describing: value)
    }

    private static func activityTypeName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .crossTraining:
            return "Cross Training"
        case .functionalStrengthTraining:
            return "Functional Strength Training"
        case .highIntensityIntervalTraining:
            return "High Intensity Interval Training"
        case .running:
            return "Running"
        case .rowing:
            return "Rowing"
        case .walking:
            return "Walking"
        case .other:
            return "Other"
        default:
            return "Activity type \(type.rawValue)"
        }
    }

    private static func workoutEventTypeName(for type: HKWorkoutEventType) -> String {
        switch type {
        case .pause:
            return "pause"
        case .resume:
            return "resume"
        case .lap:
            return "lap"
        case .marker:
            return "marker"
        case .motionPaused:
            return "motion paused"
        case .motionResumed:
            return "motion resumed"
        case .segment:
            return "segment"
        case .pauseOrResumeRequest:
            return "pause or resume request"
        @unknown default:
            return "event type \(type.rawValue)"
        }
    }

    private static func readableTimeSinceEnd(_ interval: TimeInterval) -> String {
        if interval < 0 {
            return "workout ends in \(readableDuration(-interval))"
        }

        return "\(readableDuration(interval)) since workout ended"
    }

    private static func readableDuration(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval.rounded())
        let days = totalSeconds / 86_400
        let hours = (totalSeconds % 86_400) / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        }
        if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        }
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

private struct SegmentParseError: Error {
    let reason: String
}

private enum HeartRateQueryError: LocalizedError {
    case workoutNotFound(UUID)
    case heartRateTypeUnavailable

    var errorDescription: String? {
        switch self {
        case let .workoutNotFound(uuid):
            return "Workout \(uuid.uuidString) was not found."
        case .heartRateTypeUnavailable:
            return "The HealthKit heart-rate type is unavailable."
        }
    }
}
