import SwiftUI

@MainActor
struct WorkoutReview: View {
    let row: WorkoutRow

    @Environment(\.colorScheme) private var colourScheme

    private var segments: [ReviewSegment]? {
        let segmentEvents = row.events.filter { event in
            event.typeName == "segment" && event.metadata["HYROXSegmentName"] != nil
        }
        if !segmentEvents.isEmpty {
            return ReviewSegment.fromEvents(
                segmentEvents,
                workoutDuration: row.duration
            )
        }

        guard let encodedSegments = row.metadata["HYROXSegments"] else {
            return nil
        }
        return ReviewSegment.parse(encodedSegments)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.xl) {
                header

                if let segments, !segments.isEmpty {
                    segmentSection(segments)
                    totalsSection(segments)
                } else if row.hasHyroxMetadata {
                    unavailableSegments
                } else {
                    noMetadata
                }

                limitations
            }
            .padding(DesignTokens.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DesignTokens.background(for: colourScheme).ignoresSafeArea())
        .foregroundStyle(DesignTokens.primaryText(for: colourScheme))
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.l) {
            VStack(alignment: .leading, spacing: DesignTokens.xs) {
                Text("WORKOUT REVIEW")
                    .font(DesignTokens.caption)
                    .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
                Text(row.startDate.formatted(date: .complete, time: .shortened))
                    .font(DesignTokens.title)
                categoryMarker(.measured)
            }

            HStack(alignment: .top, spacing: DesignTokens.xl) {
                metric(
                    label: "TOTAL DURATION",
                    value: Self.durationText(row.duration),
                    category: .measured
                )
                metric(
                    label: "ACTIVE ENERGY",
                    value: activeEnergyText,
                    category: .measured
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.l)
        .background(DesignTokens.surface(for: colourScheme))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.s))
    }

    private func segmentSection(_ segments: [ReviewSegment]) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.m) {
            sectionTitle("Segments")

            VStack(spacing: DesignTokens.xs) {
                ForEach(segments) { segment in
                    segmentRow(segment)
                }
            }
        }
    }

    private func segmentRow(_ segment: ReviewSegment) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.m) {
            HStack(spacing: DesignTokens.s) {
                Image(systemName: segment.kind.icon)
                    .font(DesignTokens.body)
                    .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
                Text(segment.name)
                    .font(DesignTokens.body)
            }

            HStack(alignment: .top, spacing: DesignTokens.xl) {
                metric(
                    label: "START OFFSET",
                    value: "+" + Self.durationText(segment.startOffset),
                    category: .marked
                )

                VStack(alignment: .leading, spacing: DesignTokens.xs) {
                    metric(
                        label: "DURATION",
                        value: segment.duration.map(Self.durationText) ?? "—",
                        category: .derived
                    )
                    Text(segment.durationSource)
                        .font(DesignTokens.caption)
                        .foregroundStyle(DesignTokens.caution(for: colourScheme))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.m)
        .background(DesignTokens.surface(for: colourScheme))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.s))
    }

    private func totalsSection(_ segments: [ReviewSegment]) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.m) {
            sectionTitle("Totals")

            VStack(spacing: DesignTokens.xs) {
                totalRow("Run", kind: .run, segments: segments)
                totalRow("Roxzone", kind: .roxzone, segments: segments)
                totalRow("Station", kind: .station, segments: segments)
            }
        }
    }

    private func totalRow(
        _ label: String,
        kind: ReviewSegment.Kind,
        segments: [ReviewSegment]
    ) -> some View {
        let matchingSegments = segments.filter { $0.kind == kind }
        let durations = matchingSegments.compactMap(\.duration)
        let hasUnknownDuration = durations.count != matchingSegments.count
        let total = durations.reduce(TimeInterval.zero, +)

        return HStack(alignment: .top, spacing: DesignTokens.m) {
            Image(systemName: kind.icon)
                .font(DesignTokens.body)
                .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
            Text(label)
                .font(DesignTokens.body)
            Spacer()
            VStack(alignment: .trailing, spacing: DesignTokens.xs) {
                Text(hasUnknownDuration ? "—" : Self.durationText(total))
                    .font(DesignTokens.data)
                categoryMarker(.derived)
                Text(
                    hasUnknownDuration
                        ? "INCOMPLETE — A SEGMENT END WAS NEVER RECORDED"
                        : "FROM MARKED TIMES"
                )
                    .font(DesignTokens.caption)
                    .foregroundStyle(DesignTokens.caution(for: colourScheme))
            }
        }
        .padding(DesignTokens.m)
        .background(DesignTokens.surface(for: colourScheme))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.s))
    }

    private var noMetadata: some View {
        messageSection(
            title: "No HYROX metadata",
            message: "This workout has no segment marks. Only the measured workout summary is available."
        )
    }

    private var unavailableSegments: some View {
        messageSection(
            title: "Segment data unavailable",
            message: "HYROX metadata is present, but its segment marks cannot be read reliably."
        )
    }

    private var limitations: some View {
        VStack(alignment: .leading, spacing: DesignTokens.m) {
            sectionTitle("What this cannot tell you")
            VStack(alignment: .leading, spacing: DesignTokens.s) {
                limitation("Why a station was slow")
                limitation("Whether you are improving")
                limitation("Whether your pacing was correct")
                limitation("Anything about injury or health")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.l)
        .background(DesignTokens.surface(for: colourScheme))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.s))
    }

    private func limitation(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.s) {
            Text("—")
                .foregroundStyle(DesignTokens.critical(for: colourScheme))
            Text(text)
                .font(DesignTokens.body)
        }
    }

    private func messageSection(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.s) {
            Text(title)
                .font(DesignTokens.title)
            Text(message)
                .font(DesignTokens.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.l)
        .background(DesignTokens.surface(for: colourScheme))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.s))
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(DesignTokens.title)
    }

    private func metric(
        label: String,
        value: String,
        category: TrustCategory
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.xs) {
            Text(label)
                .font(DesignTokens.caption)
                .foregroundStyle(DesignTokens.secondaryText(for: colourScheme))
            Text(value)
                .font(DesignTokens.data)
            categoryMarker(category)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func categoryMarker(_ category: TrustCategory) -> some View {
        Text(category.rawValue)
            .font(DesignTokens.caption)
            .foregroundStyle(category.foreground(for: colourScheme))
            .padding(.horizontal, DesignTokens.s)
            .padding(.vertical, DesignTokens.xs)
            .background(category.background(for: colourScheme))
            .clipShape(Capsule())
    }

    private var activeEnergyText: String {
        guard let energy = row.totalActiveEnergyKilocalories else {
            return "Not recorded"
        }
        return energy.formatted(.number.precision(.fractionLength(0))) + " kcal"
    }

    // Button-press timestamps do not justify sub-second precision, so segment
    // offsets, durations, and their totals are always rendered to whole seconds.
    private static func durationText(_ interval: TimeInterval) -> String {
        let roundedSeconds = Int(interval.rounded())
        let sign = roundedSeconds < 0 ? "−" : ""
        let magnitude = abs(roundedSeconds)
        let hours = magnitude / 3_600
        let minutes = (magnitude % 3_600) / 60
        let seconds = magnitude % 60

        if hours > 0 {
            return "\(sign)\(hours)h \(minutes)m \(seconds)s"
        }
        if minutes > 0 {
            return "\(sign)\(minutes)m \(seconds)s"
        }
        return "\(sign)\(seconds)s"
    }
}

private enum TrustCategory: String {
    case measured = "MEASURED"
    case marked = "MARKED"
    case derived = "DERIVED"

    func foreground(for colourScheme: ColorScheme) -> Color {
        switch self {
        case .measured:
            return DesignTokens.surface(for: colourScheme)
        case .marked:
            return DesignTokens.surface(for: colourScheme)
        case .derived:
            return DesignTokens.surface(for: colourScheme)
        }
    }

    func background(for colourScheme: ColorScheme) -> Color {
        switch self {
        case .measured:
            return DesignTokens.accent(for: colourScheme)
        case .marked:
            return DesignTokens.secondaryText(for: colourScheme)
        case .derived:
            return DesignTokens.caution(for: colourScheme)
        }
    }
}

private struct ReviewSegment: Identifiable {
    enum Kind: Equatable {
        case run
        case roxzone
        case station

        var icon: String {
            switch self {
            case .run:
                return DesignTokens.runIcon
            case .roxzone:
                return DesignTokens.transitionIcon
            case .station:
                return DesignTokens.stationIcon
            }
        }
    }

    let id: Int
    let name: String
    let kind: Kind
    let startOffset: TimeInterval
    let duration: TimeInterval?
    let durationSource: String

    static func fromEvents(
        _ events: [WorkoutEventRecord],
        workoutDuration: TimeInterval
    ) -> [ReviewSegment] {
        events.enumerated().compactMap { index, event in
            guard let name = event.metadata["HYROXSegmentName"],
                  let kind = Kind(name: name),
                  event.startOffset.isFinite,
                  event.duration.isFinite else {
                return nil
            }

            let segmentEndOffset = event.startOffset + event.duration
            let endsWithWorkout = abs(segmentEndOffset - workoutDuration) <= 1
            return ReviewSegment(
                id: index,
                name: name,
                kind: kind,
                startOffset: event.startOffset,
                duration: event.duration,
                durationSource: endsWithWorkout
                    ? "FROM MARKED + MEASURED"
                    : "FROM TWO MARKED TIMES"
            )
        }
    }

    static func parse(_ encoded: String) -> [ReviewSegment]? {
        let entries = encoded.split(separator: ";", omittingEmptySubsequences: false)
        var marks: [(name: String, offset: TimeInterval)] = []

        for entry in entries {
            let parts = entry.split(
                separator: "@",
                maxSplits: 1,
                omittingEmptySubsequences: false
            )
            guard parts.count == 2,
                  !parts[0].isEmpty,
                  let offset = TimeInterval(parts[1]),
                  offset.isFinite else {
                return nil
            }
            marks.append((name: String(parts[0]), offset: offset))
        }

        return marks.enumerated().compactMap { index, mark in
            guard let kind = Kind(name: mark.name) else {
                return nil
            }
            let hasNextMark = marks.indices.contains(index + 1)
            return ReviewSegment(
                id: index,
                name: mark.name,
                kind: kind,
                startOffset: mark.offset,
                duration: hasNextMark
                    ? marks[index + 1].offset - mark.offset
                    : nil,
                durationSource: hasNextMark
                    ? "FROM TWO MARKED TIMES"
                    : "SEGMENT END WAS NEVER RECORDED"
            )
        }
    }
}

private extension ReviewSegment.Kind {
    init?(name: String) {
        let normalisedName = name.lowercased()
        if normalisedName.hasPrefix("run ") {
            self = .run
        } else if normalisedName.hasPrefix("roxzone ") {
            self = .roxzone
        } else if normalisedName.hasPrefix("station ") {
            self = .station
        } else {
            return nil
        }
    }
}
