// Cycle L1 on-device controls and readouts for experiments E1.0-E1.3.

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

    var body: some View {
        List {
            Section("E1.0 HealthKit") {
                Text(healthKitAuth.isAvailable ? "HealthKit available" : "HealthKit unavailable")
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
                Text(healthKitAuth.authorizationResult)
                Text(healthKitAuth.roundTripResult)
                Text(healthKitAuth.foreignReadResult)
            }

            Section("E1.1 No session") {
                Button(backgroundProbe.isRunning ? "Stop baseline" : "Start baseline") {
                    backgroundProbe.isRunning ? backgroundProbe.stop() : backgroundProbe.start()
                }
                Text(backgroundProbe.isRunning ? "Running" : "Stopped")
                elapsedReadout(
                    ticks: backgroundProbe.tickCount,
                    elapsedByTicks: backgroundProbe.elapsedByTicks,
                    elapsedByDate: backgroundProbe.elapsedByDate,
                    startDate: backgroundProbe.isRunning ? backgroundProbe.startDate : nil
                )
                Text(backgroundProbe.latestResult)
            }

            Section("E1.2 Workout session") {
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
                Text(
                    attachHYROXMetadata &&
                    workoutManager.sessionStartDate != nil &&
                    machine.completedSegmentCount > 0
                        ? "Next end: attach metadata (\(machine.completedSegmentCount) segments)"
                        : "Next end: no metadata (\(machine.completedSegmentCount) segments ready)"
                )
                Text("Next end: attach \(machine.segmentBoundaries().count) segment events")
                Text(workoutManager.isStarting ? "Workout starting" : (workoutManager.isRunning ? "Workout running" : "Workout stopped"))
                elapsedReadout(
                    ticks: workoutManager.tickCount,
                    elapsedByTicks: workoutManager.elapsedByTicks,
                    elapsedByDate: workoutManager.elapsedByDate,
                    startDate: workoutManager.sessionStartDate
                )
                Text(workoutManager.latestHeartRate.map { "Heart rate: \(Int($0.rounded())) bpm" } ?? "Heart rate: —")
                Text(workoutManager.latestResult)
            }

            Section("E1.3 Recovery") {
                Button(recoveryProbe.isRecovering ? "Recovering…" : "Attempt recovery") {
                    Task { _ = await recoveryProbe.attemptRecovery() }
                }
                .disabled(recoveryProbe.isRecovering)
                Text(recoveryProbe.latestResult)
                Button("E2.0b Recover twice") {
                    Task { _ = await recoveryProbe.attemptRecoveryTwice() }
                }
                .disabled(recoveryProbe.isRecovering)
                Button("E2.0b Release session") {
                    recoveryProbe.releaseRetainedSession()
                }
                Text(recoveryProbe.latestTwiceResult)
            }

            Section("E2.0 Crash relaunch") {
                Text(crashProbe.summary)
                Button("E2.0 Crash now") {
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

            Section("E2.2 Persistence") {
                Text(machine.restoreReport)
                Text(machine.report)
                Button("Start protocol") {
                    machine.start()
                }
                Button("Advance") {
                    machine.advance()
                }
                Button("Undo") {
                    machine.undo()
                }
                Button("Reset") {
                    machine.reset()
                }
                Button("E4.0 Seed full race (25 segments)") {
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
                    Text(seedFullRaceReport)
                }
                if let sessionStart = workoutManager.sessionStartDate {
                    if let offsets = machine.healthKitSegmentOffsetRange(
                        sessionStart: sessionStart
                    ) {
                        Text("HYROXSegments: \(machine.healthKitSegmentsCharacterCount(sessionStart: sessionStart)) characters (\(machine.completedSegmentCount) segments); first offset \(offsets.first, format: .number.precision(.fractionLength(3)))s, last offset \(offsets.last, format: .number.precision(.fractionLength(3)))s")
                    } else {
                        Text("HYROXSegments: \(machine.healthKitSegmentsCharacterCount(sessionStart: sessionStart)) characters (\(machine.completedSegmentCount) segments); first offset —, last offset —")
                    }
                } else {
                    Text("HYROXSegments: start workout to calculate (\(machine.completedSegmentCount) segments); first offset —, last offset —")
                }
                Picker("Crash point", selection: $selectedCrashPoint) {
                    ForEach(StateStore.CrashPoint.allCases, id: \.self) { point in
                        Text(point.rawValue).tag(point)
                    }
                }
                Button("E2.2b Save with crash point") {
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
                Button("E2.2b Inspect disk") {
                    machine.refreshDiskReport()
                }
                Text(machine.diskReport)
                Button("E2.2b Clean temp files") {
                    machine.cleanUpTempFiles()
                }
            }

            Section("E2.3 Reconciliation") {
                Button("E2.3 Attach HK session") {
                    if let start = workoutManager.sessionStartDate {
                        // HKWorkoutSession has no public UUID until the workout is
                        // finished, so identity is carried by the start instant.
                        machine.attachHealthKitSession(
                            startDate: start,
                            uuid: "unavailable-until-finished"
                        )
                        reconciliationAttachReport = "Attached HK session start \(start.formatted(date: .omitted, time: .standard))."
                    } else {
                        reconciliationAttachReport = "No workout session is running — start E1.2 first."
                    }
                }
                Text(reconciliationAttachReport)
                Button("E2.3 Compare records") {
                    machine.refreshReconciliation()
                }
                Text(machine.reconciliationReport)
            }

            Section("Design system") {
                NavigationLink("Style preview") {
                    StylePreview()
                }
            }
        }
    }

    @ViewBuilder
    private func elapsedReadout(
        ticks: Int,
        elapsedByTicks: TimeInterval,
        elapsedByDate: TimeInterval,
        startDate: Date?
    ) -> some View {
        Text("Ticks: \(ticks)")
        Text("By ticks: \(elapsedByTicks, format: .number.precision(.fractionLength(1)))s")
        Text("By date: \(elapsedByDate, format: .number.precision(.fractionLength(1)))s")
        // Rendered by the system, not by this app's timer. It keeps counting
        // smoothly while the app is suspended, so the display carries none of
        // the coalescing lag the tick counter above exists to measure.
        if let startDate {
            HStack {
                Text("By system:")
                Text(timerInterval: startDate...Date.distantFuture, countsDown: false)
                    .monospacedDigit()
            }
        } else {
            Text("By system: —")
        }
    }
}
