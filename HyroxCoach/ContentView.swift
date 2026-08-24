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
                        WorkoutDetailView(row: row)
                    } label: {
                        WorkoutRowView(row: row)
                    }
                }
                .refreshable {
                    await workoutHistory.refresh()
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

    private func durationText(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        return formatter.string(from: duration) ?? "\(Int(duration.rounded())) seconds"
    }
}
