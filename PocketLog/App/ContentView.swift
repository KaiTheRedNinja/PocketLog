import SwiftUI
import Playgrounds

struct ContentView: View {
    @State var audioManager = AudioManager()
    @State var pastRecordsManager = PastRecordsManager()

    var body: some View {
        List {
            Section {
                Text(audioManager.permissionGranted ? "Permission granted" : "Need permission")
            }

            Section {
                HStack {
                    Image(systemName: audioManager.currentRecording == nil ? "record.circle" : "stop.circle")
                        .resizable()
                        .foregroundStyle(Color.primary)
                        .onTapGesture {
                            if audioManager.currentRecording == nil {
                                audioManager.beginNewRecording()
                            } else {
                                audioManager.endRecording()
                            }
                        }
                        .frame(width: 100, height: 100)

                    Image(systemName: audioManager.isRecording ? "pause.circle" : "play.circle")
                        .resizable()
                        .foregroundStyle(audioManager.currentRecording == nil ? Color.secondary : Color.primary)
                        .onTapGesture {
                            if audioManager.isRecording {
                                audioManager.pauseRecording()
                            } else {
                                audioManager.resumeRecording()
                            }
                        }
                        .frame(width: 100, height: 100)
                        .disabled(audioManager.currentRecording == nil)
                }
                .buttonStyle(.plain)
            }

            Section {
                Button("Reload records") {
                    _ = Task {
                        do {
                            try await pastRecordsManager.populate()
                        } catch {
                            print("Could not populate past records")
                        }
                    }
                }
                ForEach(pastRecordsManager.records) { record in
                    Text(record.name)
                }
            }

            Section {
                Button("Wipe", role: .destructive) {
                    do {
                        try pastRecordsManager.deleteAllInRoot()
                    } catch {
                        print("Could not wipe")
                    }
                }
            }
        }
        .task {
            async let a = audioManager.requestRecordingPermission()
            async let b = pastRecordsManager.populate()

            do {
                _ = try await (a, b)
            } catch {
                print("Something failed?")
            }
        }
    }
}
