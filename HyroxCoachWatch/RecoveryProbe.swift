// E1.3: active workout-session recovery probe.

import Foundation
import Combine
import HealthKit
import OSLog

@MainActor
final class RecoveryProbe: ObservableObject {
    @Published private(set) var isRecovering = false
    @Published private(set) var latestResult = "Not attempted"

    private let healthStore = HKHealthStore()

    func attemptRecovery() async -> String {
        isRecovering = true
        defer { isRecovering = false }
        AppLog.workout.info("\(AppLog.stamp(), privacy: .public) E1.3 attempting active workout recovery")

        do {
            let session = try await recoverSession()
            guard let session else {
                let result = "No active workout session was available to recover"
                latestResult = result
                AppLog.workout.info("\(AppLog.stamp(), privacy: .public) E1.3 no active session recovered")
                return result
            }

            _ = session.associatedWorkoutBuilder()
            let startDescription = session.startDate?.formatted(date: .abbreviated, time: .standard) ?? "unknown"
            let result = "Recovered state \(stateDescription(session.state)); start \(startDescription); associated builder: yes"
            latestResult = result
            AppLog.workout.info("\(AppLog.stamp(), privacy: .public) E1.3 recovered state=\(session.state.rawValue) start=\(startDescription, privacy: .public) associatedBuilder=true")
            return result
        } catch {
            let result = "Recovery failed: \(error.localizedDescription)"
            latestResult = result
            AppLog.workout.error("\(AppLog.stamp(), privacy: .public) E1.3 recovery failed: \(error.localizedDescription, privacy: .public)")
            return result
        }
    }

    private func recoverSession() async throws -> HKWorkoutSession? {
        try await withCheckedThrowingContinuation { continuation in
            healthStore.recoverActiveWorkoutSession { session, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: session)
                }
            }
        }
    }

    private func stateDescription(_ state: HKWorkoutSessionState) -> String {
        switch state {
        case .notStarted: return "not started"
        case .running: return "running"
        case .ended: return "ended"
        case .paused: return "paused"
        case .prepared: return "prepared"
        case .stopped: return "stopped"
        @unknown default: return "unknown (\(state.rawValue))"
        }
    }
}
