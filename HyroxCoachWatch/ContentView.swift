// Cycle L1 on-device controls and readouts for experiments E1.0-E1.3.

import SwiftUI
import HealthKit

struct ContentView: View {
    @StateObject private var healthKitAuth = HealthKitAuth()
    @StateObject private var backgroundProbe = BackgroundProbe()
    @StateObject private var workoutManager = WorkoutSessionManager()
    @StateObject private var recoveryProbe = RecoveryProbe()

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
                Text(healthKitAuth.authorizationResult)
                Text(healthKitAuth.roundTripResult)
            }

            Section("E1.1 No session") {
                Button(backgroundProbe.isRunning ? "Stop baseline" : "Start baseline") {
                    backgroundProbe.isRunning ? backgroundProbe.stop() : backgroundProbe.start()
                }
                Text(backgroundProbe.isRunning ? "Running" : "Stopped")
                elapsedReadout(
                    ticks: backgroundProbe.tickCount,
                    elapsedByTicks: backgroundProbe.elapsedByTicks,
                    elapsedByDate: backgroundProbe.elapsedByDate
                )
                Text(backgroundProbe.latestResult)
            }

            Section("E1.2 Workout session") {
                Button(workoutManager.isRunning || workoutManager.isEnding ? "End workout" : "Start cross training") {
                    if workoutManager.isRunning || workoutManager.isEnding {
                        workoutManager.end()
                    } else {
                        workoutManager.start(activityType: .crossTraining)
                    }
                }
                .disabled(workoutManager.isEnding || workoutManager.isStarting)
                Text(workoutManager.isStarting ? "Workout starting" : (workoutManager.isRunning ? "Workout running" : "Workout stopped"))
                elapsedReadout(
                    ticks: workoutManager.tickCount,
                    elapsedByTicks: workoutManager.elapsedByTicks,
                    elapsedByDate: workoutManager.elapsedByDate
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
            }
        }
    }

    @ViewBuilder
    private func elapsedReadout(
        ticks: Int,
        elapsedByTicks: TimeInterval,
        elapsedByDate: TimeInterval
    ) -> some View {
        Text("Ticks: \(ticks)")
        Text("By ticks: \(elapsedByTicks, format: .number.precision(.fractionLength(1)))s")
        Text("By date: \(elapsedByDate, format: .number.precision(.fractionLength(1)))s")
    }
}
