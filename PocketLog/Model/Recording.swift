//
//  Recording.swift
//  PocketLog
//
//  Created by Kai Quan Tay on 16/11/26.
//

import Foundation

/// Information about a recording that is in progress.
struct ActiveRecording: Identifiable, Hashable {
    /// The ID for this recording
    var id: String
    /// The name of this file in the file system
    var fileName: String { id + ".m4a" }
    /// The date and time that this recording was started
    var startDate: Date
    /// Whether this file is actively recording
    var isRecording: Bool = true
}

/// Information about a recording that has concluded.
///
/// This is constructed using up to three pieces of information:
/// - The name of the file in the file system
/// - The metadata of the file
/// - The renamed log
struct Recording: Identifiable, Hashable {
    /// The ID of this recording. This is used to identify the specific file.
    var id: String
    /// The name of this file in the file system
    var fileName: String { id + ".m4a" }

    /// The name of this document given by the user, if any
    var name: String

    /// The date and time that this recording was saved, in the metadata
    var saveDate: Date
    /// The duration of the recording, in seconds
    var duration: TimeInterval
    // TODO: determine if we want to keep track of location?
}

extension Date {
    func fileFormat() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        formatter.locale = .current
        formatter.timeZone = .current

        return formatter.string(from: self)
    }

    func displayFormat() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        formatter.locale = .current
        formatter.timeZone = .current

        return formatter.string(from: self)
    }
}
