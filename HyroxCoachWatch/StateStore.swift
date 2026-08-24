// E2.2: atomic persistence for the semantic workout record.

import Foundation
import OSLog

struct StateStore {
    enum CrashPoint: String, CaseIterable {
        case none
        case beforeTempWrite
        case duringTempWrite
        case afterTempWriteBeforeReplace
    }

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
    var crashPoint: CrashPoint = .none

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

        if crashPoint == .beforeTempWrite {
            crash(at: .beforeTempWrite)
        }

        if crashPoint == .duringTempWrite {
            let truncatedData = data.prefix(data.count / 2)
            try Data(truncatedData).write(
                to: urls.temporary,
                options: .withoutOverwriting
            )
            try flushToDisk(at: urls.temporary)
            crash(at: .duringTempWrite)
        }

        try data.write(to: urls.temporary, options: .withoutOverwriting)

        if crashPoint == .afterTempWriteBeforeReplace {
            try flushToDisk(at: urls.temporary)
            crash(at: .afterTempWriteBeforeReplace)
        }

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

    func inspect() -> String {
        do {
            let urls = try persistenceURLs()
            let temporaryDescription = fileDescription(at: urls.temporary)

            guard fileManager.fileExists(atPath: urls.file.path) else {
                return [
                    "Real file: absent",
                    "Temp file: \(temporaryDescription)"
                ].joined(separator: "\n")
            }

            do {
                let data = try Data(contentsOf: urls.file)
                let decoder = JSONDecoder()
                let version = try decoder.decode(
                    SchemaEnvelope.self,
                    from: data
                ).schemaVersion
                guard version == WorkoutState.currentSchemaVersion else {
                    return [
                        "Real file: present but undecodable (\(data.count) bytes; unsupported schema \(version))",
                        "Temp file: \(temporaryDescription)"
                    ].joined(separator: "\n")
                }
                _ = try decoder.decode(WorkoutState.self, from: data)
                return [
                    "Real file: present and valid (\(data.count) bytes)",
                    "Temp file: \(temporaryDescription)"
                ].joined(separator: "\n")
            } catch {
                return [
                    "Real file: present but undecodable (\(fileDescription(at: urls.file)); \(error.localizedDescription))",
                    "Temp file: \(temporaryDescription)"
                ].joined(separator: "\n")
            }
        } catch {
            return "Disk inspection unavailable: \(error.localizedDescription)"
        }
    }

    func cleanUpTempFiles() throws {
        let urls = try persistenceURLs()
        guard fileManager.fileExists(atPath: urls.temporary.path) else {
            return
        }
        try fileManager.removeItem(at: urls.temporary)
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

    private func fileDescription(at url: URL) -> String {
        guard fileManager.fileExists(atPath: url.path) else {
            return "absent"
        }

        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            guard let size = attributes[.size] as? NSNumber else {
                return "present (byte size unavailable)"
            }
            return "present (\(size.intValue) bytes)"
        } catch {
            return "present (byte size unavailable: \(error.localizedDescription))"
        }
    }

    private func flushToDisk(at url: URL) throws {
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.synchronize()
    }

    private func crash(at point: CrashPoint) -> Never {
        let defaults = UserDefaults.standard
        defaults.set(point.rawValue, forKey: "e22b.lastCrashPoint")
        defaults.set(Date(), forKey: "e22b.lastCrashDate")
        // os_log may not flush before the process dies.
        defaults.synchronize()
        AppLog.lifecycle.fault("\(AppLog.stamp(), privacy: .public) E2.2b deliberate crash point=\(point.rawValue, privacy: .public)")
        fatalError("E2.2b crash: \(point.rawValue)")
    }

    private struct SchemaEnvelope: Decodable {
        let schemaVersion: Int
    }
}
