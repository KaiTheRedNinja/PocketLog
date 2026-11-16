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

            Circle()
                .stroke(Color.white)
                .fill(audioManager.isRecording ? .red : .black)
                .onTapGesture {
                    if audioManager.isRecording {
                        audioManager.endRecording()
                    } else {
                        audioManager.beginRecording()
                    }
                }
                .frame(width: 100, height: 100)
        }
    }
}
