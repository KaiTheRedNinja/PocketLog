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

        recordingSession = AVAudioSession.sharedInstance()
        do {
            // Set the audio session category and mode.
            try recordingSession!.setCategory(.playAndRecord, mode: .default)
        } catch {
            print("Could not set category for recording session")
        }
    }

    func beginNewRecording() {
        let newRecording = ActiveRecording(startDate: .now)
        let filepath = documentsDir().appendingPathComponent(newRecording.filename)
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
        currentRecording = nil
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
