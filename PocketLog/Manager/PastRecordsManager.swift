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
                    let url = await FileSystem.path(for: File.recording(name: audioFileName))
                    let asset = AVURLAsset(url: url)
                    do {
                        let saveDate = try await asset.load(.creationDate)
                        let duration = try await asset.load(.duration)

                        let attr = try FileManager.default.attributesOfItem(atPath: url.path)

                        let newRecord = Recording(
                            id: fileNameNoExtension,
                            name: renames[fileNameNoExtension] ?? fileNameNoExtension,
                            saveDate: saveDate?.startDate ?? (attr[FileAttributeKey.modificationDate] as? Date) ?? .distantPast,
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

    /// Deletes the records at the given offsets permenantly
    func delete(offsets: IndexSet) {
        let recordsToRemove = offsets.map { records[$0] }
        records.remove(atOffsets: offsets)
        for record in recordsToRemove {
            // delete from file system
            do {
                try FileSystem.delete(.recording(name: record.fileName))
            } catch {
                print("Could not delete file \(record.fileName): \(error)")
            }
        }
    }

    /// Saves all renamings
    func save() {
        var newMap: [String: String] = [:]
        for record in records where record.name != record.id {
            newMap[record.id] = record.name
        }
        do {
            try FileSystem.write(value: newMap, to: .renames)
        } catch {
            print("Could not update renames: \(error)")
        }
    }
}
