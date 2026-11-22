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

    /// Resumes the current recording if one exists. Starts a new recording if one doesn't.
    func beginOrResumeRecording() {
        if currentRecording == nil {
            beginNewRecording()
        } else {
            resumeRecording()
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

@Observable
class AudioPlayback: NSObject {
    var recording: Recording?
    var isPlaying: Bool

    @ObservationIgnored var recordingSession: AVAudioSession?
    var player: AVAudioPlayer?

    init(recording: Recording?) {
        self.recording = recording
        self.player = nil
        self.isPlaying = false
    }

    func load(recording: Recording, playAfterLoad: Bool = false) {
        self.recording = recording
        let url = FileSystem.path(for: .recording(name: recording.fileName))

        recordingSession = AVAudioSession.sharedInstance()
        do {
            // Set the audio session category and mode.
            try recordingSession!.setCategory(.playAndRecord, mode: .default)
        } catch {
            print("Could not set category for recording session")
        }

        isPlaying = false
        do {
            player = try AVAudioPlayer(contentsOf: url)
            guard let player else {
                print("Could not create player")
                return
            }
            player.volume = 1.0
            player.delegate = self
            recordingSession?.activate(options: []) { [weak self] success, error in
                guard let self else { return }

                guard success else {
                    print("Audio session reactivation failed: \(String(describing: error))")
                    eject()
                    return
                }

                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    player.prepareToPlay()
                    if playAfterLoad {
                        self?.beginOrResume()
                    }
                    print("Recording prepped")
                }
            }
        } catch {
            print("Could not begin playing: \(error)")
        }
    }

    func eject() {
        recording = nil
        player?.pause()
        player = nil
        isPlaying = false
    }

    func beginOrResume() {
        guard let player else { return }
        player.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }
}

extension AudioPlayback: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        withAnimation {
            isPlaying = false
        }
    }
}
