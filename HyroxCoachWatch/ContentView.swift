// Cycle L1-L6 on-device controls and readouts.
//
// The race screen is the product surface. Everything else is an instrument
// and lives behind "Instruments", so the first screen is short enough to read
// at a glance mid-effort. No control has been removed: the experiments still
// depend on all of them.

import SwiftUI
import HealthKit

struct ContentView: View {
    @ObservedObject var crashProbe: CrashProbe

    @StateObject private var healthKitAuth = HealthKitAuth()
    @StateObject private var backgroundProbe = BackgroundProbe()
    @StateObject private var workoutManager = WorkoutSessionManager()
    @StateObject private var recoveryProbe = RecoveryProbe()
    @StateObject private var machine = ProtocolMachine()
    @State private var isShowingCrashConfirmation = false
    @State private var selectedCrashPoint = StateStore.CrashPoint.none
    @State private var isShowingPersistenceCrashConfirmation = false
    @State private var reconciliationAttachReport = "HK session not attached."
    @State private var attachHYROXMetadata = false
    @State private var isShowingSeedFullRaceConfirmation = false
    @State private var seedFullRaceReport = ""

    @Environment(\.colorScheme) private var colourScheme

    var body: some View {
        // Added 2026-09-04. There was no navigation container at all, so the
        // existing link to the style preview silently did nothing.
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        raceScreen
                    } label: {
                        raceSummaryRow
                    }
                }

                Section("Instruments") {
                    instrumentLink("Workout session", "E1.2", destination: workoutScreen)
                    instrumentLink("HealthKit", "E1.0", destination: healthKitScreen)
                    instrumentLink("Baseline, no session", "E1.1", destination: baselineScreen)
                    instrumentLink("Recovery", "E1.3 · E2.0b", destination: recoveryScreen)
                    instrumentLink("Crash and persistence", "E2.0 · E2.2 · E4.0", destination: persistenceScreen)
                    instrumentLink("Reconciliation", "E2.3", destination: reconciliationScreen)
                }

                Section("Design system") {
                    NavigationLink("Style preview") {
                        StylePreview()
                    }
                }
            }
            .navigationTitle("HyroxCoach")
        }
    }

    // MARK: - Root rows

    private var raceSummaryRow: some View {
        VStack(alignment: .leading, spacing: DesignTokens.xs) {
            Text("RACE")
                .font(DesignTokens.caption)
                .foregroundStyle(DesignTokens.accent(for: colourScheme))
            Text(machine.currentStateDescription)
                .font(DesignTokens.title)
                .foregroundStyle(DesignTokens.primaryText(for: colourScheme))
            Text("\(machine.completedSegmentCount) segments complete")
                .font(DesignTokens.caption)
                .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
        }
        .padding(.vertical, DesignTokens.xs)
    }

    @ViewBuilder
    private func instrumentLink<Destination: View>(
        _ title: String,
        _ subtitle: String,
        destination: Destination
    ) -> some View {
        NavigationLink {
            destination
        } label: {
            VStack(alignment: .leading, spacing: DesignTokens.xs) {
                Text(title)
                    .font(DesignTokens.body)
                    .foregroundStyle(DesignTokens.primaryText(for: colourScheme))
                Text(subtitle)
                    .font(DesignTokens.caption)
                    .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
            }
        }
    }

    // MARK: - Race

    private var raceScreen: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: DesignTokens.s) {
                    Text(machine.currentStateDescription)
                        .font(DesignTokens.title)
                        .foregroundStyle(DesignTokens.primaryText(for: colourScheme))
                    // System-rendered, so it keeps counting while the app is
                    // suspended. See L1's note on display dilation.
                    if let sessionStart = workoutManager.sessionStartDate {
                        Text(timerInterval: sessionStart...Date.distantFuture, countsDown: false)
                            .font(DesignTokens.display)
                            .monospacedDigit()
                            .foregroundStyle(DesignTokens.accent(for: colourScheme))
                    } else {
                        Text("no workout running")
                            .font(DesignTokens.caption)
                            .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
                    }
                    Text("\(machine.completedSegmentCount) segments complete")
                        .font(DesignTokens.caption)
                        .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
                }
                .padding(.vertical, DesignTokens.xs)
            }

            Section {
                Button("Advance") { machine.advance() }
                Button("Undo") { machine.undo() }
            }

            Section {
                Button("Start protocol") { machine.start() }
                Button("Reset", role: .destructive) { machine.reset() }
            }

            Section("Detail") {
                diagnostic(machine.restoreReport)
                diagnostic(machine.report)
            }
        }
        .navigationTitle("Race")
    }

    // MARK: - Instruments

    private var workoutScreen: some View {
        List {
            Section {
                Toggle("Attach HYROX metadata", isOn: $attachHYROXMetadata)
                Button(workoutManager.isRunning || workoutManager.isEnding ? "End workout" : "Start cross training") {
                    if workoutManager.isRunning || workoutManager.isEnding {
                        if attachHYROXMetadata,
                           let sessionStart = workoutManager.sessionStartDate {
                            workoutManager.end(
                                metadata: machine.healthKitMetadata(
                                    sessionStart: sessionStart
                                ),
                                boundaries: machine.segmentBoundaries()
                            )
                        } else {
                            workoutManager.end(
                                boundaries: machine.segmentBoundaries()
                            )
                        }
                    } else {
                        workoutManager.start(activityType: .crossTraining)
                    }
                }
                .disabled(workoutManager.isEnding || workoutManager.isStarting)
                Text(workoutManager.isStarting ? "Workout starting" : (workoutManager.isRunning ? "Workout running" : "Workout stopped"))
                    .font(DesignTokens.body)
                    .foregroundStyle(DesignTokens.primaryText(for: colourScheme))
                Text(workoutManager.latestHeartRate.map { "Heart rate: \(Int($0.rounded())) bpm" } ?? "Heart rate: —")
                    .font(DesignTokens.body)
                    .foregroundStyle(DesignTokens.primaryText(for: colourScheme))
            }

            Section("Elapsed") {
                elapsedReadout(
                    ticks: workoutManager.tickCount,
                    elapsedByTicks: workoutManager.elapsedByTicks,
                    elapsedByDate: workoutManager.elapsedByDate,
                    startDate: workoutManager.sessionStartDate
                )
            }

            Section("Next end") {
                diagnostic(
                    attachHYROXMetadata &&
                    workoutManager.sessionStartDate != nil &&
                    machine.completedSegmentCount > 0
                        ? "Attach metadata (\(machine.completedSegmentCount) segments)"
                        : "No metadata (\(machine.completedSegmentCount) segments ready)"
                )
                diagnostic("Attach \(machine.segmentBoundaries().count) segment events")
                diagnostic(workoutManager.latestResult)
            }
        }
        .navigationTitle("Workout")
    }

    private var healthKitScreen: some View {
        List {
            Section {
                Text(healthKitAuth.isAvailable ? "HealthKit available" : "HealthKit unavailable")
                    .font(DesignTokens.body)
                    .foregroundStyle(
                        healthKitAuth.isAvailable
                            ? DesignTokens.primaryText(for: colourScheme)
                            : DesignTokens.critical(for: colourScheme)
                    )
                Button(healthKitAuth.isBusy ? "Working…" : "Request authorization") {
                    Task { await healthKitAuth.requestAuthorization() }
                }
                .disabled(healthKitAuth.isBusy || !healthKitAuth.isAvailable)
                Button("Write + read 1 kcal") {
                    Task { _ = await healthKitAuth.writeAndReadBackSample() }
                }
                .disabled(healthKitAuth.isBusy || !healthKitAuth.isAvailable)
                Button("E1.0b Read foreign data") {
                    Task { _ = await healthKitAuth.readForeignSamples() }
                }
                .disabled(healthKitAuth.isBusy || !healthKitAuth.isAvailable)
            }

            Section("Result") {
                diagnostic(healthKitAuth.authorizationResult)
                diagnostic(healthKitAuth.roundTripResult)
                diagnostic(healthKitAuth.foreignReadResult)
            }
        }
        .navigationTitle("HealthKit")
    }

    private var baselineScreen: some View {
        List {
            Section {
                Button(backgroundProbe.isRunning ? "Stop baseline" : "Start baseline") {
                    backgroundProbe.isRunning ? backgroundProbe.stop() : backgroundProbe.start()
                }
                Text(backgroundProbe.isRunning ? "Running" : "Stopped")
                    .font(DesignTokens.body)
                    .foregroundStyle(DesignTokens.primaryText(for: colourScheme))
            }

            Section("Elapsed") {
                elapsedReadout(
                    ticks: backgroundProbe.tickCount,
                    elapsedByTicks: backgroundProbe.elapsedByTicks,
                    elapsedByDate: backgroundProbe.elapsedByDate,
                    startDate: backgroundProbe.isRunning ? backgroundProbe.startDate : nil
                )
            }

            Section("Result") {
                diagnostic(backgroundProbe.latestResult)
            }
        }
        .navigationTitle("Baseline")
    }

    private var recoveryScreen: some View {
        List {
            Section {
                Button(recoveryProbe.isRecovering ? "Recovering…" : "Attempt recovery") {
                    Task { _ = await recoveryProbe.attemptRecovery() }
                }
                .disabled(recoveryProbe.isRecovering)
                diagnostic(recoveryProbe.latestResult)
            }

            Section("E2.0b Idempotency") {
                Button("Recover twice") {
                    Task { _ = await recoveryProbe.attemptRecoveryTwice() }
                }
                .disabled(recoveryProbe.isRecovering)
                Button("Release session") {
                    recoveryProbe.releaseRetainedSession()
                }
                diagnostic(recoveryProbe.latestTwiceResult)
            }
        }
        .navigationTitle("Recovery")
    }

    private var persistenceScreen: some View {
        List {
            Section("E2.0 Crash relaunch") {
                diagnostic(crashProbe.summary)
                Button("Crash now", role: .destructive) {
                    isShowingCrashConfirmation = true
                }
                .confirmationDialog(
                    "Deliberately crash the app?",
                    isPresented: $isShowingCrashConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Crash app", role: .destructive) {
                        crashProbe.crashNow()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will end the current experiment run.")
                }
            }

            Section("E4.0 Full race") {
                Button("Seed full race (25 segments)") {
                    if workoutManager.isRunning,
                       workoutManager.sessionStartDate != nil {
                        seedFullRaceReport = ""
                        isShowingSeedFullRaceConfirmation = true
                    } else {
                        seedFullRaceReport = "A workout session has to be started first."
                    }
                }
                .confirmationDialog(
                    "Overwrite the current protocol with a seeded full race?",
                    isPresented: $isShowingSeedFullRaceConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Seed full race", role: .destructive) {
                        guard workoutManager.isRunning,
                              let sessionStart = workoutManager.sessionStartDate else {
                            seedFullRaceReport = "A workout session has to be started first."
                            return
                        }
                        machine.seedFullRace(sessionStart: sessionStart)
                        seedFullRaceReport = "Seeded test data from the running workout session start."
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This is test data, not a real workout.")
                }
                if !seedFullRaceReport.isEmpty {
                    diagnostic(seedFullRaceReport)
                }
                if let sessionStart = workoutManager.sessionStartDate {
                    if let offsets = machine.healthKitSegmentOffsetRange(
                        sessionStart: sessionStart
                    ) {
                        diagnostic("HYROXSegments: \(machine.healthKitSegmentsCharacterCount(sessionStart: sessionStart)) characters (\(machine.completedSegmentCount) segments); first offset \(offsets.first.formatted(.number.precision(.fractionLength(3))))s, last offset \(offsets.last.formatted(.number.precision(.fractionLength(3))))s")
                    } else {
                        diagnostic("HYROXSegments: \(machine.healthKitSegmentsCharacterCount(sessionStart: sessionStart)) characters (\(machine.completedSegmentCount) segments); first offset —, last offset —")
                    }
                } else {
                    diagnostic("HYROXSegments: start workout to calculate (\(machine.completedSegmentCount) segments); first offset —, last offset —")
                }
            }

            Section("E2.2b Atomicity") {
                Picker("Crash point", selection: $selectedCrashPoint) {
                    ForEach(StateStore.CrashPoint.allCases, id: \.self) { point in
                        Text(point.rawValue).tag(point)
                    }
                }
                Button("Save with crash point", role: .destructive) {
                    isShowingPersistenceCrashConfirmation = true
                }
                .disabled(selectedCrashPoint == .none)
                .confirmationDialog(
                    "Save and deliberately crash the app?",
                    isPresented: $isShowingPersistenceCrashConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Save and crash", role: .destructive) {
                        machine.crashPoint = selectedCrashPoint
                        // advance(), not start(): the crash must land inside a
                        // TRANSITION write on the existing protocol. start()
                        // wrote a fresh empty state, which made the truncated
                        // temp file 132 bytes instead of half the real payload
                        // and left the transition-loss window untested.
                        machine.advance()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will end the app at \(selectedCrashPoint.rawValue).")
                }
                Button("Inspect disk") {
                    machine.refreshDiskReport()
                }
                diagnostic(machine.diskReport)
                Button("Clean temp files") {
                    machine.cleanUpTempFiles()
                }
            }
        }
        .navigationTitle("Persistence")
    }

    private var reconciliationScreen: some View {
        List {
            Section {
                Button("Attach HK session") {
                    if let start = workoutManager.sessionStartDate {
                        // HKWorkoutSession has no public UUID until the workout is
                        // finished, so identity is carried by the start instant.
                        machine.attachHealthKitSession(
                            startDate: start,
                            uuid: "unavailable-until-finished"
                        )
                        reconciliationAttachReport = "Attached HK session start \(start.formatted(date: .omitted, time: .standard))."
                    } else {
                        reconciliationAttachReport = "No workout session is running — start the workout first."
                    }
                }
                diagnostic(reconciliationAttachReport)
            }

            Section {
                Button("Compare records") {
                    machine.refreshReconciliation()
                }
                diagnostic(machine.reconciliationReport)
            }
        }
        .navigationTitle("Reconciliation")
    }

    // MARK: - Shared readouts

    /// Diagnostic text is deliberately quieter than the controls above it. It
    /// is evidence to read when something is wrong, not the primary surface.
    private func diagnostic(_ text: String) -> some View {
        Text(text)
            .font(DesignTokens.caption)
            .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
    }

    @ViewBuilder
    private func elapsedReadout(
        ticks: Int,
        elapsedByTicks: TimeInterval,
        elapsedByDate: TimeInterval,
        startDate: Date?
    ) -> some View {
        // Rendered by the system, not by this app's timer. It keeps counting
        // smoothly while the app is suspended, so the display carries none of
        // the coalescing lag the tick counter below exists to measure. It is
        // shown first because it is the only one of the three an athlete
        // should ever be asked to read.
        if let startDate {
            HStack {
                Text("By system")
                    .font(DesignTokens.caption)
                    .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
                Spacer()
                Text(timerInterval: startDate...Date.distantFuture, countsDown: false)
                    .font(DesignTokens.data)
                    .monospacedDigit()
                    .foregroundStyle(DesignTokens.accent(for: colourScheme))
            }
        } else {
            readoutRow("By system", "—")
        }
        readoutRow("By date", "\(elapsedByDate.formatted(.number.precision(.fractionLength(1))))s")
        readoutRow("By ticks", "\(elapsedByTicks.formatted(.number.precision(.fractionLength(1))))s")
        readoutRow("Ticks", "\(ticks)")
    }

    private func readoutRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(DesignTokens.caption)
                .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
            Spacer()
            Text(value)
                .font(DesignTokens.data)
                .foregroundStyle(DesignTokens.primaryText(for: colourScheme))
        }
    }
}
