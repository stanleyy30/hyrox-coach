// AppLog.swift
// Shared logging for the iOS and watchOS sides of the Cycle L1 experiment.

import Foundation
import OSLog

public enum AppLog {
    public static let lifecycle: Logger = Logger(
        subsystem: "com.stanleyyoung.HyroxCoach",
        category: "lifecycle"
    )
    public static let health: Logger = Logger(
        subsystem: "com.stanleyyoung.HyroxCoach",
        category: "health"
    )
    public static let workout: Logger = Logger(
        subsystem: "com.stanleyyoung.HyroxCoach",
        category: "workout"
    )

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    // These logs are the experimental evidence: Console.app can filter them by subsystem,
    // and they survive app suspension, making the gap in timestamps visible.
    public static func stamp() -> String {
        dateFormatter.string(from: Date())
    }
}
