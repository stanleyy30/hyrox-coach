// E1.3: active workout-session recovery probe.

import Foundation
import Combine
import HealthKit
import OSLog

@MainActor
final class RecoveryProbe: ObservableObject {
    @Published private(set) var isRecovering = false
    @Published private(set) var latestResult = "Not attempted"
    @Published private(set) var latestTwiceResult = "Not attempted"

    private let healthStore = HKHealthStore()
    // A discarded recovered session may leave a registration behind, which is one of the things under test.
    private var retainedSession: HKWorkoutSession?
    private var retainedBuilder: HKLiveWorkoutBuilder?

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

            retainedSession = session
            retainedBuilder = session.associatedWorkoutBuilder()
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

    func attemptRecoveryTwice() async -> String {
        isRecovering = true
        defer { isRecovering = false }

        let firstOutcome = await recoveryOutcome(call: 1)
        retainSession(from: firstOutcome)
        let secondOutcome = await recoveryOutcome(call: 2)
        retainSession(from: secondOutcome)

        if firstOutcome.isRecovered && secondOutcome.isRecovered {
            AppLog.workout.info("\(AppLog.stamp(), privacy: .public) E2.0b two sessions were returned; retaining the second")
        }

        let verdict = firstOutcome.kind == secondOutcome.kind ? "IDENTICAL" : "DIFFERENT"
        let result = """
        CALL 1: \(outcomeDescription(firstOutcome))
        CALL 2: \(outcomeDescription(secondOutcome))
        VERDICT: \(verdict)
        """
        latestTwiceResult = result
        return result
    }

    func releaseRetainedSession() {
        retainedSession = nil
        retainedBuilder = nil
        AppLog.workout.info("\(AppLog.stamp(), privacy: .public) E2.0b released retained session and builder references")
    }

    private enum RecoveryOutcome {
        case recovered(HKWorkoutSession)
        case none
        case failed(String)

        enum Kind: Equatable {
            case recovered
            case none
            case failed
        }

        var kind: Kind {
            switch self {
            case .recovered: return .recovered
            case .none: return .none
            case .failed: return .failed
            }
        }

        var isRecovered: Bool {
            if case .recovered = self { return true }
            return false
        }
    }

    private func recoveryOutcome(call: Int) async -> RecoveryOutcome {
        do {
            guard let session = try await recoverSession() else {
                AppLog.workout.info("\(AppLog.stamp(), privacy: .public) E2.0b CALL \(call, privacy: .public) nil")
                return .none
            }

            let startDescription = session.startDate?.formatted(date: .abbreviated, time: .standard) ?? "unknown"
            AppLog.workout.info("\(AppLog.stamp(), privacy: .public) E2.0b CALL \(call, privacy: .public) recovered state=\(session.state.rawValue, privacy: .public) startDate=\(startDescription, privacy: .public)")
            return .recovered(session)
        } catch {
            let description = error.localizedDescription
            AppLog.workout.error("\(AppLog.stamp(), privacy: .public) E2.0b CALL \(call, privacy: .public) failed: \(description, privacy: .public)")
            return .failed(description)
        }
    }

    private func retainSession(from outcome: RecoveryOutcome) {
        guard case let .recovered(session) = outcome else { return }
        retainedSession = session
        retainedBuilder = session.associatedWorkoutBuilder()
    }

    private func outcomeDescription(_ outcome: RecoveryOutcome) -> String {
        switch outcome {
        case let .recovered(session):
            let startDescription = session.startDate?.formatted(date: .abbreviated, time: .standard) ?? "unknown"
            return "recovered (state: \(stateDescription(session.state)); startDate: \(startDescription))"
        case .none:
            return "nil"
        case let .failed(description):
            return "error: \(description)"
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
