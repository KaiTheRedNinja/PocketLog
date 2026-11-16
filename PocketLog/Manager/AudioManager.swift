//
//  AudioManager.swift
//  PocketLog
//
//  Created by Kai Quan Tay on 16/11/26.
//

import AVFoundation
import SwiftUI

@Observable
class AudioManager: NSObject {
    var permissionGranted: Bool = false
    var isRecording: Bool = false

    @ObservationIgnored var recordingSession: AVAudioSession?
    @ObservationIgnored var audioRecorder: AVAudioRecorder?

    func requestRecordingPermission() async {
        permissionGranted = await AVAudioApplication.requestRecordPermission()

        if !permissionGranted {
            print("User did not grant permission!")
            return
        }

        recordingSession = AVAudioSession.sharedInstance()
        do {
            // Set the audio session category and mode.
            try recordingSession!.setCategory(.playAndRecord, mode: .default)
        } catch {
            print("Could not set category for recording session")
        }
    }

    func beginRecording() {
        let fileId = UUID()
        let filename = "recording_\(fileId.uuidString).m4a"
        let filepath = documentsDir().appendingPathComponent(filename)

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: filepath, settings: settings)
        } catch {
            print("Failed to create audio recorder!")
            isRecording = false
            return
        }

        isRecording = true

        audioRecorder!.delegate = self
        recordingSession?.activate(options: []) { [weak self] success, error in
            guard let self else { return }

            guard success else {
                print("Audio session activation failed: \(String(describing: error))")
                isRecording = false
                return
            }

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self else { return }
                let success = audioRecorder!.record()
                isRecording = success
                print("Recording started: \(success)")
            }
        }
    }

    func endRecording() {
        isRecording = false
        audioRecorder?.stop()
        audioRecorder = nil

        print("Ended recording. File is located at ", documentsDir().appendingPathComponent("recording.m4a").absoluteString)
    }

    func documentsDir() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

extension AudioManager: AVAudioRecorderDelegate {
}
