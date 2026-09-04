// ContentView.swift
// iOS companion UI for observing workouts delivered through HealthKit.
//
// The workout list is the product surface. Authorisation and refresh controls
// sit in a single compact section above it rather than occupying the top of
// the screen, and the diagnostics live inside each workout's detail.

import SwiftUI

struct ContentView: View {
    @StateObject private var healthKitStatus = HealthKitStatus()
    @StateObject private var workoutHistory = WorkoutHistory()
    @State private var isRequestingAuthorization = false

    @Environment(\.colorScheme) private var colourScheme

    var body: some View {
        NavigationStack {
            List {
                if workoutHistory.rows.isEmpty {
                    Section {
                        emptyState
                    }
                } else {
                    Section {
                        ForEach(workoutHistory.rows) { row in
                            NavigationLink {
                                WorkoutDetailView(row: row, workoutHistory: workoutHistory)
                            } label: {
                                WorkoutRowView(row: row)
                            }
                        }
                    } header: {
                        sectionHeader("Workouts")
                    }
                }

                Section {
                    if !healthKitStatus.isAvailable {
                        Text("HealthKit is unavailable on this iPhone.")
                            .font(DesignTokens.body)
                            .foregroundStyle(DesignTokens.critical(for: colourScheme))
                    }
                    Button("Request HealthKit authorisation") {
                        isRequestingAuthorization = true

                        Task { @MainActor in
                            await healthKitStatus.requestAuthorization()
                            isRequestingAuthorization = false
                            await workoutHistory.refresh()
                        }
                    }
                    .disabled(!healthKitStatus.isAvailable || isRequestingAuthorization)
                    caption(workoutHistory.statusLine)
                    if let lastRefreshed = workoutHistory.lastRefreshed {
                        caption(
                            "Last refreshed "
                                + lastRefreshed.formatted(date: .abbreviated, time: .standard)
                        )
                    } else {
                        caption("Last refreshed never")
                    }
                } header: {
                    sectionHeader("HealthKit")
                }

                Section {
                    // Was previously a Section nested inside a VStack, outside
                    // any List, with the preview embedded inline. It is a link
                    // now, which is what it was always meant to be.
                    NavigationLink("Style preview") {
                        StylePreview()
                    }
                } header: {
                    sectionHeader("Design system")
                }
            }
            .refreshable {
                await workoutHistory.refresh()
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await workoutHistory.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(workoutHistory.isLoading)
                }
            }
            .task {
                await workoutHistory.refresh()
            }
        }
    }

    /// Recorded in L5 and confirmed on 2026-09-04: a refused read and an empty
    /// store are indistinguishable, because HealthKit returns an empty result
    /// for both and never reports the refusal. The screen must therefore not
    /// assert that there are no workouts.
    private var emptyState: some View {
        VStack(alignment: .leading, spacing: DesignTokens.s) {
            if let newest = workoutHistory.mostRecentTimeSinceEnded {
                Text(newest)
                    .font(DesignTokens.body)
                    .foregroundStyle(DesignTokens.primaryText(for: colourScheme))
            }
            Text("Nothing to show")
                .font(DesignTokens.title)
                .foregroundStyle(DesignTokens.primaryText(for: colourScheme))
            Text("Either there are no workouts, or permission to read them was not granted. HealthKit reports both the same way, so this screen cannot tell them apart.")
                .font(DesignTokens.body)
                .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
            Text("If you expected workouts here, check Settings › Health › Data Access & Devices.")
                .font(DesignTokens.caption)
                .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
        }
        .padding(.vertical, DesignTokens.s)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(DesignTokens.caption)
            .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(DesignTokens.caption)
            .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
    }
}

private struct WorkoutRowView: View {
    let row: WorkoutRow

    @Environment(\.colorScheme) private var colourScheme

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.xs) {
            Text("\(row.activityTypeName) · \(durationText(row.duration))")
                .font(DesignTokens.body)
                .foregroundStyle(DesignTokens.primaryText(for: colourScheme))
            Text(row.startDate.formatted(date: .abbreviated, time: .shortened))
                .font(DesignTokens.caption)
                .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
            Text("\(row.sourceName) · \(row.deviceName)")
                .font(DesignTokens.caption)
                .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
            if let marker = row.hyroxIntegrityMarker {
                Text("HYROX · \(marker)")
                    .font(DesignTokens.caption)
                    .foregroundStyle(DesignTokens.accent(for: colourScheme))
            }
        }
        .padding(.vertical, DesignTokens.xs)
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

    @Environment(\.colorScheme) private var colourScheme

    var body: some View {
        List {
            // The review is the product surface. It used to sit at the bottom
            // of the identity fields, below the UUID, which put the only
            // screen an athlete would want behind seven diagnostics.
            Section {
                NavigationLink {
                    WorkoutReview(row: row)
                } label: {
                    VStack(alignment: .leading, spacing: DesignTokens.xs) {
                        Text("Review this workout")
                            .font(DesignTokens.body)
                            .foregroundStyle(DesignTokens.accent(for: colourScheme))
                        Text("Segments, durations, and where each number came from")
                            .font(DesignTokens.caption)
                            .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
                    }
                    .padding(.vertical, DesignTokens.xs)
                }
            }

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
                verdict(row.hyroxIntegrity)
                if row.hyroxIntegrity.hasPrefix("IMPLAUSIBLE: ") {
                    Text(
                        "Plausibility failure: "
                            + String(row.hyroxIntegrity.dropFirst("IMPLAUSIBLE: ".count))
                    )
                        .font(DesignTokens.body)
                        .foregroundStyle(DesignTokens.critical(for: colourScheme))
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
                    verdict(heartRateSummary.status)

                    if heartRateSummary.sampleCount > 0 {
                        field("Count", String(heartRateSummary.sampleCount))
                        field("Minimum", heartRateText(heartRateSummary.minimum))
                        field("Maximum", heartRateText(heartRateSummary.maximum))
                        field("Average", heartRateText(heartRateSummary.average))
                    } else if heartRateSummary.status == "NO SAMPLES" {
                        Text("The query succeeded and found no heart-rate samples.")
                        .font(DesignTokens.body)
                        .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
                    }
                }
            }

            Section("Segment sources") {
                verdict(row.segmentSourceAgreement)
            }

            Section("Workout events") {
                verdict(row.eventSummary)

                if row.events.isEmpty {
                    Text(
                        "This workout carries no events. This is normal for apps that do not record structure."
                    )
                    .font(DesignTokens.body)
                    .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
                } else {
                    ForEach(row.events) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.typeName)
                                .font(DesignTokens.body)
                                .foregroundStyle(DesignTokens.accent(for: colourScheme))
                            field("Start offset", eventOffsetText(event.startOffset))
                            field("Duration", eventDurationText(event.duration))

                            if !event.metadata.isEmpty {
                                Text("Metadata")
                                    .font(DesignTokens.caption)
                                    .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
                                ForEach(event.metadata.keys.sorted(), id: \.self) { key in
                                    field(key, event.metadata[key] ?? "")
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Section("Metadata") {
                if row.metadata.isEmpty {
                    Text("No metadata")
                        .font(DesignTokens.body)
                        .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
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
        VStack(alignment: .leading, spacing: DesignTokens.xs) {
            Text(name)
                .font(DesignTokens.caption)
                .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
            Text(value)
                .font(DesignTokens.body)
                .foregroundStyle(DesignTokens.primaryText(for: colourScheme))
                .textSelection(.enabled)
        }
        .padding(.vertical, DesignTokens.xs)
    }

    /// A verdict line. These are the sentences that decide whether the data can
    /// be trusted, so they are the only text in the detail rendered at title
    /// weight. Everything else here is a field.
    private func verdict(_ text: String) -> some View {
        Text(text)
            .font(DesignTokens.title)
            .foregroundStyle(DesignTokens.primaryText(for: colourScheme))
            .textSelection(.enabled)
            .padding(.vertical, DesignTokens.xs)
    }

    private func heartRateText(_ value: Double?) -> String {
        guard let value else { return "Not available" }
        return value.formatted(.number.precision(.fractionLength(0...1))) + " bpm"
    }

    private func eventOffsetText(_ offset: TimeInterval) -> String {
        String(format: "%.3f seconds", offset)
    }

    private func eventDurationText(_ duration: TimeInterval) -> String {
        String(format: "%.3f seconds", duration)
    }

    private func durationText(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        return formatter.string(from: duration) ?? "\(Int(duration.rounded())) seconds"
    }
}
