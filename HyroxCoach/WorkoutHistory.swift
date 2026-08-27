// WorkoutHistory.swift
// Reads recent workouts on iPhone so HealthKit delivery from Apple Watch can be observed.

import Combine
import Foundation
import HealthKit

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

    var id: UUID { uuid }

    var hasHyroxMetadata: Bool {
        metadata.keys.contains { $0.hasPrefix("HYROX") }
    }

    var hyroxReceivedSegmentLength: Int? {
        metadata["HYROXSegments"]?.count
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

    private static func makeRow(from workout: HKWorkout) -> WorkoutRow {
        let deviceName = workout.device?.name
            ?? workout.sourceRevision.productType
            ?? "unknown"

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
            )
        )

        AppLog.health.info(
            "[\(AppLog.stamp(), privacy: .public)] HYROX metadata integrity; workout: \(row.uuid.uuidString, privacy: .public); verdict: \(row.hyroxIntegrity, privacy: .public)"
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
