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
                            saveDate: saveDate?.startDate ?? (attr[FileAttributeKey.creationDate] as? Date) ?? .distantPast,
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
            return recordings.sorted(by: { $0.saveDate < $1.saveDate }) // oldest to newest
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

enum DateCategory: Equatable {
    /// Recording was made today, defined as the recording occuring in the same calendar day as today.
    case today
    /// Recording was made N days ago, where `N < 7`. A day is defined as 24 hours.
    case daysAgo(Int)
    /// Recording was made N weeks ago, where `1 <= N < 5`. A week is defined as 7 days.
    case weeksAgo(Int)
    /// Recording was made N months ago, where `1 <= N < 12`. A month is defined as 30.4375 days (365.25 / 12).
    case monthsAgo(Int)
    /// Recording was made N years ago, where `1 <= N`
    case yearsAgo(Int)

    var description: String {
        switch self {
        case .today:
            "Today"
        case .daysAgo(let int):
            "\(int) days ago"
        case .weeksAgo(let int):
            "\(int) weeks ago"
        case .monthsAgo(let int):
            "\(int) months ago"
        case .yearsAgo(let int):
            "\(int) years ago"
        }
    }
}

extension Date {
    /// The `DateCategory` relative to a given reference, or `Date.now`
    func category(reference: Date = .now) -> DateCategory {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .current

        let startOfSelf = calendar.startOfDay(for: self)
        let startOfRef = calendar.startOfDay(for: reference)

        if startOfRef == startOfSelf { return .today }

        let components = calendar.dateComponents([.day, .weekOfYear, .month, .year], from: self, to: reference)

        let day = components.day ?? 0
        let weekOfYear = components.weekOfYear ?? 0
        let month = components.month ?? 0
        let year = components.year ?? 0

        if day == 0 {
            return .today
        } else if day < 7 {
            return .daysAgo(day)
        } else if weekOfYear < 5 {
            return .weeksAgo(weekOfYear)
        } else if month < 12 {
            return .monthsAgo(month)
        } else {
            return .yearsAgo(year)
        }
    }
}
