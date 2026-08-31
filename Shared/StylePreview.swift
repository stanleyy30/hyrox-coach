import SwiftUI

struct StylePreview: View {
    @Environment(\.colorScheme) private var colourScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.xl) {
                tokenSection("Colour") {
                    VStack(alignment: .leading, spacing: DesignTokens.s) {
                        colourSwatch("Background", DesignTokens.background(for: colourScheme))
                        colourSwatch("Surface", DesignTokens.surface(for: colourScheme))
                        colourSwatch("Primary text", DesignTokens.primaryText(for: colourScheme))
                        colourSwatch("Secondary text", DesignTokens.secondaryText(for: colourScheme))
                        colourSwatch("Accent", DesignTokens.accent(for: colourScheme))
                        colourSwatch("Positive", DesignTokens.positive(for: colourScheme))
                        colourSwatch("Caution", DesignTokens.caution(for: colourScheme))
                        colourSwatch("Critical", DesignTokens.critical(for: colourScheme))
                    }
                }

                tokenSection("Type") {
                    VStack(alignment: .leading, spacing: DesignTokens.m) {
                        typeSample("Display", sample: "Race ready", font: DesignTokens.display)
                        typeSample("Title", sample: "Sled push", font: DesignTokens.title)
                        typeSample("Body", sample: "Recover before the next station", font: DesignTokens.body)
                        typeSample("Caption", sample: "LAP 3 OF 8", font: DesignTokens.caption)
                        typeSample("Data", sample: "08:42.6  172 BPM", font: DesignTokens.data)
                    }
                }

                tokenSection("Spacing") {
                    VStack(alignment: .leading, spacing: DesignTokens.m) {
                        spacingSample("XS", value: DesignTokens.xs)
                        spacingSample("S", value: DesignTokens.s)
                        spacingSample("M", value: DesignTokens.m)
                        spacingSample("L", value: DesignTokens.l)
                        spacingSample("XL", value: DesignTokens.xl)
                    }
                }

                tokenSection("Iconography") {
                    VStack(alignment: .leading, spacing: DesignTokens.m) {
                        iconSample("Run", symbol: DesignTokens.runIcon)
                        iconSample("Station", symbol: DesignTokens.stationIcon)
                        iconSample("Transition", symbol: DesignTokens.transitionIcon)
                        iconSample("Timer", symbol: DesignTokens.timerIcon)
                        iconSample("Heart rate", symbol: DesignTokens.heartRateIcon)
                    }
                }
            }
            .padding(DesignTokens.m)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DesignTokens.background(for: colourScheme).ignoresSafeArea())
        .foregroundStyle(DesignTokens.primaryText(for: colourScheme))
    }

    private func tokenSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.m) {
            Text(title)
                .font(DesignTokens.title)
            content()
        }
        .padding(DesignTokens.m)
        .background(DesignTokens.surface(for: colourScheme))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.s))
    }

    private func colourSwatch(_ label: String, _ colour: Color) -> some View {
        HStack(spacing: DesignTokens.m) {
            RoundedRectangle(cornerRadius: DesignTokens.xs)
                .fill(colour)
                .frame(width: DesignTokens.xl, height: DesignTokens.xl)
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.xs)
                        .stroke(DesignTokens.secondaryText(for: colourScheme))
                }
            Text(label)
                .font(DesignTokens.body)
        }
    }

    private func typeSample(_ label: String, sample: String, font: Font) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.xs) {
            Text(label)
                .font(DesignTokens.caption)
                .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
            Text(sample)
                .font(font)
        }
    }

    private func spacingSample(_ label: String, value: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.xs) {
            Text(label)
                .font(DesignTokens.caption)
            RoundedRectangle(cornerRadius: DesignTokens.xs)
                .fill(DesignTokens.accent(for: colourScheme))
                .frame(maxWidth: .infinity)
                .frame(height: value)
        }
    }

    private func iconSample(_ label: String, symbol: String) -> some View {
        HStack(spacing: DesignTokens.m) {
            Image(systemName: symbol)
                .font(DesignTokens.title)
                .foregroundStyle(DesignTokens.accent(for: colourScheme))
            Text(label)
                .font(DesignTokens.body)
        }
    }
}
