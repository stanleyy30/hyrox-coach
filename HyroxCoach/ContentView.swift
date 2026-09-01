// ContentView.swift
// Plain iOS companion UI for observing workouts delivered through HealthKit.

import SwiftUI

struct ContentView: View {
    @StateObject private var healthKitStatus = HealthKitStatus()
    @StateObject private var workoutHistory = WorkoutHistory()
    @State private var isRequestingAuthorization = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(
                    healthKitStatus.isAvailable
                        ? "HealthKit is available on this iPhone."
                        : "HealthKit is unavailable on this iPhone."
                )

                Button("Request HealthKit authorisation") {
                    isRequestingAuthorization = true

                    Task { @MainActor in
                        await healthKitStatus.requestAuthorization()
                        isRequestingAuthorization = false
                    }
                }
                .disabled(!healthKitStatus.isAvailable || isRequestingAuthorization)

                Button("Refresh") {
                    Task {
                        await workoutHistory.refresh()
                    }
                }
                .disabled(workoutHistory.isLoading)

                Text(workoutHistory.statusLine)

                if let lastRefreshed = workoutHistory.lastRefreshed {
                    Text(
                        "Last refreshed: "
                            + lastRefreshed.formatted(date: .abbreviated, time: .standard)
                    )
                } else {
                    Text("Last refreshed: never")
                }

                if let timeSinceEnded = workoutHistory.mostRecentTimeSinceEnded {
                    Text("Newest workout: \(timeSinceEnded)")
                        .font(.headline)
                }

                List(workoutHistory.rows) { row in
                    NavigationLink {
                        WorkoutDetailView(row: row, workoutHistory: workoutHistory)
                    } label: {
                        WorkoutRowView(row: row)
                    }
                }
                .refreshable {
                    await workoutHistory.refresh()
                }

                Section("Design system") {
                    StylePreview()
                }
            }
            .padding(.top)
            .navigationTitle("Workout History")
            .task {
                await workoutHistory.refresh()
            }
        }
    }
}

private struct WorkoutRowView: View {
    let row: WorkoutRow

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(row.startDate.formatted(date: .abbreviated, time: .standard))
            Text("\(row.activityTypeName) — \(durationText(row.duration))")
            Text("\(row.sourceName) — \(row.deviceName)")
            if let marker = row.hyroxIntegrityMarker {
                Text("HYROX — \(marker)")
            }
        }
    }

    private func durationText(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = duration >= 3_600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "\(Int(duration.rounded()))s"
    }
}

private struct WorkoutDetailView: View {
    let row: WorkoutRow
    @ObservedObject var workoutHistory: WorkoutHistory
    @State private var heartRateSummary: HeartRateSummary?
    @State private var isLoadingHeartRate = true

    var body: some View {
        List {
            Section("Workout") {
                field("UUID", row.uuid.uuidString)
                field("Start", row.startDate.formatted(date: .complete, time: .standard))
                field("End", row.endDate.formatted(date: .complete, time: .standard))
                field("Duration", durationText(row.duration))
                field("Activity type", row.activityTypeName)
                field("Source", row.sourceName)
                field("Device", row.deviceName)
                field("Total active energy", activeEnergyText)
            }

            Section("HYROX Integrity") {
                Text(row.hyroxIntegrity)
                    .font(.headline)
                    .textSelection(.enabled)
                if row.hyroxIntegrity.hasPrefix("IMPLAUSIBLE: ") {
                    Text(
                        "Plausibility failure: "
                            + String(row.hyroxIntegrity.dropFirst("IMPLAUSIBLE: ".count))
                    )
                        .font(.headline)
                        .textSelection(.enabled)
                }
                if let offsets = row.hyroxFirstAndLastOffsets {
                    field("First and last offsets", offsets)
                }
                field(
                    "Received segment-string character count",
                    row.hyroxReceivedSegmentLength.map(String.init) ?? "Not available"
                )
            }

            Section("Heart rate") {
                if isLoadingHeartRate {
                    ProgressView("Loading heart-rate samples…")
                } else if let heartRateSummary {
                    Text(heartRateSummary.status)
                        .font(.headline)
                        .textSelection(.enabled)

                    if heartRateSummary.sampleCount > 0 {
                        field("Count", String(heartRateSummary.sampleCount))
                        field("Minimum", heartRateText(heartRateSummary.minimum))
                        field("Maximum", heartRateText(heartRateSummary.maximum))
                        field("Average", heartRateText(heartRateSummary.average))
                    } else if heartRateSummary.status == "NO SAMPLES" {
                        Text("The query succeeded and found no heart-rate samples.")
                    }
                }
            }

            Section("Metadata") {
                if row.metadata.isEmpty {
                    Text("No metadata")
                } else {
                    ForEach(row.metadata.keys.sorted(), id: \.self) { key in
                        field(key, row.metadata[key] ?? "")
                    }
                }
            }
        }
        .navigationTitle("Workout Detail")
        .task(id: row.uuid) {
            isLoadingHeartRate = true
            heartRateSummary = await workoutHistory.heartRate(for: row.uuid)
            isLoadingHeartRate = false
        }
    }

    private var activeEnergyText: String {
        guard let kilocalories = row.totalActiveEnergyKilocalories else {
            return "Not available"
        }
        return kilocalories.formatted(.number.precision(.fractionLength(0...2))) + " kcal"
    }

    private func field(_ name: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .font(.caption)
            Text(value)
                .textSelection(.enabled)
        }
    }

    private func heartRateText(_ value: Double?) -> String {
        guard let value else { return "Not available" }
        return value.formatted(.number.precision(.fractionLength(0...1))) + " bpm"
    }

    private func durationText(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        return formatter.string(from: duration) ?? "\(Int(duration.rounded())) seconds"
    }
}
