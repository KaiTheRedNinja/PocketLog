//
//  PastRecordsManager.swift
//  PocketLog
//
//  Created by Kai Quan Tay on 16/11/26.
//

import SwiftUI
import AVFoundation

@Observable
@MainActor
class PastRecordsManager {
    var records: [Recording] = []

    func populate() async throws {
        let renames: [String: String] = (try? FileSystem.read(from: .renames)) ?? [:]
        let fileNames = (try? FileSystem.contents(of: .recordingsDir)) ?? []

        let audioFileNames = fileNames.filter { $0.hasSuffix(".m4a") }

        let recordings = await withTaskGroup(of: Recording?.self, returning: [Recording].self) { taskGroup in
            for audioFileName in audioFileNames {
                taskGroup.addTask {
                    let fileNameNoExtension = String(audioFileName.dropLast(4))
                    let asset = await AVURLAsset(url: FileSystem.path(for: File.recording(name: audioFileName)))
                    do {
                        let saveDate = try await asset.load(.creationDate)
                        let duration = try await asset.load(.duration)

                        let newRecord = Recording(
                            id: fileNameNoExtension,
                            name: renames[fileNameNoExtension] ?? fileNameNoExtension,
                            saveDate: saveDate?.startDate ?? .distantPast,
                            duration: duration.seconds
                        )
                        return newRecord
                    } catch {
                        print("Could not load metadata for \(audioFileName)")
                        return nil
                    }
                }
            }

            var recordings: [Recording] = []
            for await record in taskGroup {
                guard let record else { continue }
                recordings.append(record)
            }
            return recordings.sorted(by: { $0.saveDate > $1.saveDate })
        }

        self.records = recordings
    }

    func deleteAllInRoot() throws {
        let fileNames = (try? FileSystem.contents(of: .root)) ?? []
        for fileName in fileNames {
            try FileSystem.delete(.arbitrary(path: fileName))
        }
    }

    /// Saves all renamings
    func save() {
        var newMap: [String: String] = [:]
        for record in records where record.name != record.id {
            newMap[record.id] = record.name
        }
    }
}
