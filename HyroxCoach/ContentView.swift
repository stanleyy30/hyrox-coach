// ContentView.swift
// Intentionally plain iOS companion UI for the Cycle L1 HealthKit experiment.

import SwiftUI

struct ContentView: View {
    @StateObject private var healthKitStatus = HealthKitStatus()
    @State private var isRequestingAuthorization = false

    var body: some View {
        VStack {
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

            Text(
                "The iPhone side stays intentionally empty until Cycle L3. "
                    + "In that cycle, workouts saved on the watch are expected to appear here "
                    + "via HealthKit's own sync; no code in this app moves them."
            )
        }
    }
}
