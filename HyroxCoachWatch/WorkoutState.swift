// E2.2: timestamp-bearing semantic workout record.

import Foundation

struct WorkoutState: Codable {
    static let currentSchemaVersion = 2
    static let maximumUndoHistoryCount = 2

    enum Kind: Codable, Equatable {
        case idle
        case preparing
        case running(leg: Int)
        case inRoxzone(leg: Int)
        case inStation(index: Int, name: String)
        case completed
    }

    enum SegmentKind: String, Codable {
        case preparing
        case running
        case roxzone
        case station
    }

    enum SegmentIdentity: Codable {
        case preparation
        case leg(Int)
        case station(index: Int, name: String)
    }

    struct CompletedSegment: Codable {
        let kind: SegmentKind
        let identity: SegmentIdentity
        let startedAt: Date
        let endedAt: Date
    }

    struct Snapshot: Codable {
        let kind: Kind
        let stateStartedAt: Date
        let completedSegments: [CompletedSegment]
    }

    let schemaVersion: Int
    let sessionID: UUID
    let protocolStartedAt: Date
    let healthKitSessionStartDate: Date?
    let healthKitSessionUUID: String?
    let kind: Kind
    let stateStartedAt: Date
    let completedSegments: [CompletedSegment]
    let undoHistory: [Snapshot]

    init(
        schemaVersion: Int = WorkoutState.currentSchemaVersion,
        sessionID: UUID,
        protocolStartedAt: Date,
        healthKitSessionStartDate: Date? = nil,
        healthKitSessionUUID: String? = nil,
        kind: Kind,
        stateStartedAt: Date,
        completedSegments: [CompletedSegment] = [],
        undoHistory: [Snapshot] = []
    ) {
        self.schemaVersion = schemaVersion
        self.sessionID = sessionID
        self.protocolStartedAt = protocolStartedAt
        self.healthKitSessionStartDate = healthKitSessionStartDate
        self.healthKitSessionUUID = healthKitSessionUUID
        self.kind = kind
        self.stateStartedAt = stateStartedAt
        self.completedSegments = completedSegments
        self.undoHistory = Array(undoHistory.suffix(Self.maximumUndoHistoryCount))
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        sessionID = try container.decode(UUID.self, forKey: .sessionID)
        protocolStartedAt = try container.decode(Date.self, forKey: .protocolStartedAt)
        healthKitSessionStartDate = try container.decodeIfPresent(
            Date.self,
            forKey: .healthKitSessionStartDate
        )
        healthKitSessionUUID = try container.decodeIfPresent(
            String.self,
            forKey: .healthKitSessionUUID
        )
        kind = try container.decode(Kind.self, forKey: .kind)
        stateStartedAt = try container.decode(Date.self, forKey: .stateStartedAt)
        completedSegments = try container.decode(
            [CompletedSegment].self,
            forKey: .completedSegments
        )
        let decodedHistory = try container.decode([Snapshot].self, forKey: .undoHistory)
        guard decodedHistory.count <= Self.maximumUndoHistoryCount else {
            throw DecodingError.dataCorruptedError(
                forKey: .undoHistory,
                in: container,
                debugDescription: "Undo history exceeds the two-snapshot bound"
            )
        }
        undoHistory = decodedHistory
    }

    var snapshot: Snapshot {
        Snapshot(
            kind: kind,
            stateStartedAt: stateStartedAt,
            completedSegments: completedSegments
        )
    }
}
