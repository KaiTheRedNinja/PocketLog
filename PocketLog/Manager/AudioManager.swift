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
    var currentRecording: ActiveRecording?

    var isRecording: Bool { currentRecording?.isRecording == true }

    @ObservationIgnored var recordingSession: AVAudioSession?
    @ObservationIgnored var audioRecorder: AVAudioRecorder?

    func requestRecordingPermission() async {
        permissionGranted = await AVAudioApplication.requestRecordPermission()

        if !permissionGranted {
            print("User did not grant permission!")
            return
        }

        do {
            try FileSystem.create(dir: .recordingsDir)
        } catch {
            print("Could not create recordings directory")
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

    func beginNewRecording() {
        let now = Date.now
        let newRecording = ActiveRecording(id: now.fileFormat(), startDate: now)
        let filepath = FileSystem.path(for: .recording(name: newRecording.fileName))
        self.currentRecording = newRecording

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
            currentRecording = nil
            return
        }

        audioRecorder!.delegate = self
        recordingSession?.activate(options: []) { [weak self] success, error in
            guard let self else { return }

            guard success else {
                print("Audio session reactivation failed: \(String(describing: error))")
                currentRecording = nil
                return
            }

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self else { return }
                let success = audioRecorder!.record()
                if success == false {
                    print("Could not restart recording")
                    currentRecording = nil
                    return
                }
                print("Recording restarted")
            }
        }
    }

    func pauseRecording() {
        audioRecorder?.pause()
        currentRecording?.isRecording = false
    }

    func resumeRecording() {
        currentRecording?.isRecording = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let success = audioRecorder!.record()
            if success == false {
                print("Could not restart recording")
                currentRecording = nil
                return
            }
            print("Recording restarted")
        }
    }

    func endRecording() {
        if let currentRecording {
            print("Ended recording. File is located at ", FileSystem.path(for: .recording(name: currentRecording.fileName)))
        }
        currentRecording = nil
        audioRecorder?.stop()
        audioRecorder = nil
    }
}

extension AudioManager: AVAudioRecorderDelegate {
}
