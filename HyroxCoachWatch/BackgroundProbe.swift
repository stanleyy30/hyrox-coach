// E1.1: no-workout-session background timer baseline.

import Foundation
import Combine
import OSLog

@MainActor
final class BackgroundProbe: ObservableObject {
    @Published private(set) var tickCount = 0
    @Published private(set) var elapsedByTicks: TimeInterval = 0
    @Published private(set) var elapsedByDate: TimeInterval = 0
    @Published private(set) var isRunning = false
    @Published private(set) var latestResult = "Not started"

    private var timer: Timer?
    private var startDate: Date?

    func start() {
        stop()
        tickCount = 0
        elapsedByTicks = 0
        elapsedByDate = 0
        startDate = Date()
        isRunning = true
        latestResult = "Running without HKWorkoutSession"
        AppLog.lifecycle.info("\(AppLog.stamp(), privacy: .public) E1.1 baseline started without workout session")

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recordTick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if isRunning {
            latestResult = "Stopped at tick \(tickCount); ticks \(format(elapsedByTicks))s vs date \(format(elapsedByDate))s"
            AppLog.lifecycle.info("\(AppLog.stamp(), privacy: .public) E1.1 baseline stopped tick=\(self.tickCount) elapsedByTicks=\(self.elapsedByTicks) elapsedByDate=\(self.elapsedByDate)")
        }
        isRunning = false
    }

    private func recordTick() {
        guard let startDate else { return }
        tickCount += 1
        elapsedByTicks = TimeInterval(tickCount)
        elapsedByDate = Date().timeIntervalSince(startDate)
        latestResult = "Tick \(tickCount)"
        AppLog.lifecycle.info("\(AppLog.stamp(), privacy: .public) E1.1 tick=\(self.tickCount) elapsedByTicks=\(self.elapsedByTicks) elapsedByDate=\(self.elapsedByDate)")
    }

    private func format(_ interval: TimeInterval) -> String {
        String(format: "%.1f", interval)
    }
}
