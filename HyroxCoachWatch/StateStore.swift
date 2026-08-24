// E2.2: atomic persistence for the semantic workout record.

import Foundation
import OSLog

struct StateStore {
    enum StoreError: LocalizedError {
        case applicationSupportUnavailable
        case unsupportedSchema(found: Int, expected: Int)

        var errorDescription: String? {
            switch self {
            case .applicationSupportUnavailable:
                return "Application Support directory is unavailable"
            case let .unsupportedSchema(found, expected):
                return "Unsupported workout state schema \(found); expected \(expected)"
            }
        }
    }

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func save(_ state: WorkoutState) throws {
        let urls = try persistenceURLs()
        try createDirectoryIfNeeded(at: urls.directory)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(state)

        if fileManager.fileExists(atPath: urls.temporary.path) {
            try fileManager.removeItem(at: urls.temporary)
        }
        try data.write(to: urls.temporary, options: .withoutOverwriting)

        if fileManager.fileExists(atPath: urls.file.path) {
            _ = try fileManager.replaceItemAt(
                urls.file,
                withItemAt: urls.temporary,
                backupItemName: nil,
                options: []
            )
        } else {
            try fileManager.moveItem(at: urls.temporary, to: urls.file)
        }

        AppLog.lifecycle.info("\(AppLog.stamp(), privacy: .public) E2.2 state saved kind=\(String(describing: state.kind), privacy: .public) segments=\(state.completedSegments.count, privacy: .public)")
    }

    func load() throws -> WorkoutState? {
        let urls = try persistenceURLs()
        guard fileManager.fileExists(atPath: urls.file.path) else {
            return nil
        }

        let data = try Data(contentsOf: urls.file)
        let decoder = JSONDecoder()
        let version = try decoder.decode(SchemaEnvelope.self, from: data).schemaVersion
        guard version == WorkoutState.currentSchemaVersion else {
            throw StoreError.unsupportedSchema(
                found: version,
                expected: WorkoutState.currentSchemaVersion
            )
        }
        return try decoder.decode(WorkoutState.self, from: data)
    }

    func clear() throws {
        let urls = try persistenceURLs()
        if fileManager.fileExists(atPath: urls.temporary.path) {
            try fileManager.removeItem(at: urls.temporary)
        }
        if fileManager.fileExists(atPath: urls.file.path) {
            try fileManager.removeItem(at: urls.file)
        }
        AppLog.lifecycle.info("\(AppLog.stamp(), privacy: .public) E2.2 persisted state cleared")
    }

    private func persistenceURLs() throws -> (
        directory: URL,
        file: URL,
        temporary: URL
    ) {
        guard let applicationSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw StoreError.applicationSupportUnavailable
        }
        let directory = applicationSupportURL.appendingPathComponent(
            "HyroxCoach",
            isDirectory: true
        )
        return (
            directory,
            directory.appendingPathComponent("workout-state.json"),
            directory.appendingPathComponent("workout-state.json.tmp")
        )
    }

    private func createDirectoryIfNeeded(at directoryURL: URL) throws {
        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }

    private struct SchemaEnvelope: Decodable {
        let schemaVersion: Int
    }
}
