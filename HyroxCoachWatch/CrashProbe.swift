// E2.0: durable launch instrumentation and deliberate-crash probe.

import Foundation
import Combine
import OSLog

final class CrashProbe: ObservableObject {
    @Published private(set) var launchCount = 0
    @Published private(set) var launchDates: [Date] = []
    @Published private(set) var lastLaunchFollowedDeliberateCrash = false
    @Published private(set) var lastCrashDate: Date?

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let launchCount = "e20.launchCount"
        static let launchDates = "e20.launchDates"
        static let lastCrashDate = "e20.lastCrashDate"
        static let crashArmed = "e20.crashArmed"
    }

    func recordLaunch() {
        let now = Date()
        let previousDates = defaults.object(forKey: Keys.launchDates) as? [Date] ?? []
        let followedDeliberateCrash = defaults.bool(forKey: Keys.crashArmed)

        launchCount = defaults.integer(forKey: Keys.launchCount) + 1
        launchDates = Array((previousDates + [now]).suffix(20))
        lastLaunchFollowedDeliberateCrash = followedDeliberateCrash
        lastCrashDate = defaults.object(forKey: Keys.lastCrashDate) as? Date

        defaults.set(launchCount, forKey: Keys.launchCount)
        defaults.set(launchDates, forKey: Keys.launchDates)
        defaults.set(false, forKey: Keys.crashArmed)

        let launchesDescription = launchDates.map(Self.timestampFormatter.string(from:)).joined(separator: ", ")
        let previousGapDescription = previousLaunchGap.map(Self.durationDescription) ?? "unavailable"
        let lastCrashDescription = lastCrashDate.map(Self.timestampFormatter.string(from:)) ?? "none"
        AppLog.lifecycle.info("\(AppLog.stamp(), privacy: .public) E2.0 launch count=\(self.launchCount, privacy: .public) date=\(Self.timestampFormatter.string(from: now), privacy: .public) followedDeliberateCrash=\(followedDeliberateCrash, privacy: .public) previousLaunchGap=\(previousGapDescription, privacy: .public) lastCrash=\(lastCrashDescription, privacy: .public) launches=\(launchesDescription, privacy: .public)")
    }

    var summary: String {
        let recentDates = launchDates.suffix(4).reversed().map {
            Self.timestampFormatter.string(from: $0)
        }
        let launches = recentDates.isEmpty ? "  none" : recentDates.map { "  \($0)" }.joined(separator: "\n")
        let followedCrash = lastLaunchFollowedDeliberateCrash ? "YES" : "no"
        let previousGap = previousLaunchGap.map(Self.durationDescription) ?? "—"

        var lines = [
            "Total launches: \(launchCount)",
            "Recent launches:\n\(launches)",
            "Latest followed crash: \(followedCrash)",
            "Gap from previous launch: \(previousGap)"
        ]

        if let lastCrashDate {
            lines.append("Last deliberate crash: \(Self.timestampFormatter.string(from: lastCrashDate))")
            if let firstLaunchAfterCrash = launchDates.first(where: { $0 >= lastCrashDate }) {
                let crashGap = firstLaunchAfterCrash.timeIntervalSince(lastCrashDate)
                lines.append("First launch after crash: \(Self.durationDescription(crashGap))")
            }
        } else {
            lines.append("Last deliberate crash: none")
        }

        return lines.joined(separator: "\n")
    }

    // os_log output may not flush before the process dies, so UserDefaults is the durable crash marker.
    func crashNow() -> Never {
        let now = Date()
        defaults.set(now, forKey: Keys.lastCrashDate)
        defaults.set(true, forKey: Keys.crashArmed)
        defaults.synchronize()
        AppLog.lifecycle.fault("\(AppLog.stamp(), privacy: .public) E2.0 deliberate crash armed at \(Self.timestampFormatter.string(from: now), privacy: .public)")
        fatalError("E2.0 deliberate crash")
    }

    private var previousLaunchGap: TimeInterval? {
        guard launchDates.count >= 2 else { return nil }
        return launchDates[launchDates.count - 1].timeIntervalSince(launchDates[launchDates.count - 2])
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d HH:mm:ss"
        return formatter
    }()

    private static func durationDescription(_ interval: TimeInterval) -> String {
        if interval < 60 {
            return String(format: "%.1fs", interval)
        }

        let totalSeconds = Int(interval.rounded())
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        }
        return "\(minutes)m \(seconds)s"
    }
}
