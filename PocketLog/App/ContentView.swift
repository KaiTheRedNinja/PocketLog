import SwiftUI
import Playgrounds

struct ContentView: View {
    @State var audioManager = AudioManager()

    var body: some View {
        VStack {
            Text(audioManager.permissionGranted ? "Permission granted" : "Need permission")
                .task {
                    await audioManager.requestRecordingPermission()
                }

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
        }
    }
}
