//
//  Recording.swift
//  PocketLog
//
//  Created by Kai Quan Tay on 16/11/26.
//

import Foundation

typealias RecordingID = UUID

/// Information about a recording that is in progress
struct ActiveRecording: Identifiable {
    var id: RecordingID
    /// The name of this document
    var filename: String { "recording_\(id).m4a" }
    /// The date and time that this recording was started
    var startDate: Date
}

/// Information about a recording that has concluded
struct Recording: Identifiable {
    var id: RecordingID
    /// The name of this document
    var filename: String { "recording_\(id).m4a" }

    /// The date and time that this recording was started
    var startDate: Date
    /// The name of the document, if any. Defaults to the date and time of recording.
    var documentName: String
    /// The duration of the recording, in seconds
    var duration: TimeInterval
    // TODO: determine if we want to keep track of location?
}
