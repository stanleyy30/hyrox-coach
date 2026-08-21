// Cycle L1 experiment harness entry point (E1.0-E1.3).

import SwiftUI

@main
struct HyroxCoachWatchApp: App {
    @StateObject private var crashProbe: CrashProbe

    init() {
        let crashProbe = CrashProbe()
        crashProbe.recordLaunch()
        _crashProbe = StateObject(wrappedValue: crashProbe)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(crashProbe: crashProbe)
        }
    }
}
