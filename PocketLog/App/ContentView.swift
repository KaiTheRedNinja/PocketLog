import SwiftUI
import Playgrounds

struct ContentView: View {
    @State var audioManager = AudioManager()
    @State var pastRecordsManager = PastRecordsManager()

    @State var exportUrl: URL?

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
                ForEach($pastRecordsManager.records) { $record in
                    VStack(alignment: .leading) {
                        TextField("", text: $record.name)
                            .onSubmit {
                                // a name cannot be left empty
                                if record.name.isEmpty {
                                    record.name = record.fileName
                                }
                                pastRecordsManager.save()
                            }
                            .contextMenu {
                                Button("Export") {
                                    do {
                                        exportUrl = try FileSystem.export(
                                            file: .recording(name: record.fileName),
                                            newName: record.name + ".m4a"
                                        )
                                    } catch {
                                        print("Could not export: \(error)")
                                        exportUrl = nil
                                    }
                                }
                            }

                        Text(record.saveDate.fileFormat())
                            .font(.caption)
                    }
                }
                .onDelete { indexSet in
                    pastRecordsManager.delete(offsets: indexSet)
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
        .sheet(item: $exportUrl) { url in
            ShareView(activityItems: [url])
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

extension URL: @retroactive Identifiable {
    public var id: String { self.path() }
}
