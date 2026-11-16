//
//  Recording.swift
//  PocketLog
//
//  Created by Kai Quan Tay on 16/11/26.
//

import Foundation

/// Information about a recording that is in progress.
///
/// Note that this does not conform to Identifiable, as we do not expect more than one active recording at a time.
struct ActiveRecording {
    /// The date and time that this recording was started
    var startDate: Date
    /// The default name of this document
    var filename: String { "\(startDate.fileFormat()).m4a" }
    /// Whether this file is actively recording
    var isRecording: Bool = true
}

/// Information about a recording that has concluded
struct Recording: Identifiable {
    var id: String { filename }

    /// The name of this document
    var filename: String

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
}
