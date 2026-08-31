// Callers must never use a literal colour, font size or spacing value; if a value is needed it belongs here.

import SwiftUI

enum DesignTokens {
    static func background(for colourScheme: ColorScheme) -> Color {
        colour(
            light: (0.96, 0.97, 0.98),
            dark: (0.03, 0.05, 0.08),
            colourScheme: colourScheme
        )
    }

    static func surface(for colourScheme: ColorScheme) -> Color {
        colour(
            light: (1.00, 1.00, 1.00),
            dark: (0.09, 0.12, 0.16),
            colourScheme: colourScheme
        )
    }

    static func primaryText(for colourScheme: ColorScheme) -> Color {
        colour(
            light: (0.05, 0.08, 0.12),
            dark: (0.95, 0.97, 1.00),
            colourScheme: colourScheme
        )
    }

    static func secondaryText(for colourScheme: ColorScheme) -> Color {
        colour(
            light: (0.32, 0.38, 0.45),
            dark: (0.63, 0.69, 0.76),
            colourScheme: colourScheme
        )
    }

    static func accent(for colourScheme: ColorScheme) -> Color {
        // E5.2 token-propagation test 2026-08-31: changed from blue
        // (0.00, 0.42, 0.64) / (0.18, 0.78, 0.96) to the signal orange of
        // the app icon. One edit here, in one file, is the whole change.
        colour(
            light: (0.83, 0.33, 0.12),
            dark: (0.96, 0.50, 0.31),
            colourScheme: colourScheme
        )
    }

    static func positive(for colourScheme: ColorScheme) -> Color {
        colour(
            light: (0.08, 0.48, 0.28),
            dark: (0.28, 0.84, 0.50),
            colourScheme: colourScheme
        )
    }

    static func caution(for colourScheme: ColorScheme) -> Color {
        colour(
            light: (0.66, 0.39, 0.00),
            dark: (1.00, 0.72, 0.20),
            colourScheme: colourScheme
        )
    }

    static func critical(for colourScheme: ColorScheme) -> Color {
        colour(
            light: (0.72, 0.12, 0.16),
            dark: (1.00, 0.35, 0.38),
            colourScheme: colourScheme
        )
    }

#if os(watchOS)
    static let display = Font.system(size: 30, weight: .bold, design: .rounded)
    static let title = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 18, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 15, weight: .medium, design: .rounded)
    static let data = Font.system(size: 20, weight: .semibold, design: .monospaced).monospacedDigit()

    static let xs: CGFloat = 3
    static let s: CGFloat = 6
    static let m: CGFloat = 10
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
#else
    static let display = Font.system(size: 40, weight: .bold, design: .rounded)
    static let title = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 17, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 13, weight: .medium, design: .rounded)
    static let data = Font.system(size: 18, weight: .semibold, design: .monospaced).monospacedDigit()

    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 20
    static let xl: CGFloat = 32
#endif

    static let runIcon = "figure.run"
    static let stationIcon = "dumbbell.fill"
    static let transitionIcon = "arrow.triangle.swap"
    static let timerIcon = "timer"
    static let heartRateIcon = "heart.fill"

    private static func colour(
        light: (red: Double, green: Double, blue: Double),
        dark: (red: Double, green: Double, blue: Double),
        colourScheme: ColorScheme
    ) -> Color {
        let components = colourScheme == .dark ? dark : light
        return Color(
            .sRGB,
            red: components.red,
            green: components.green,
            blue: components.blue,
            opacity: 1.00
        )
    }
}
