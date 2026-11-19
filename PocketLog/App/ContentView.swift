import SwiftUI
import Playgrounds

struct ContentView: View {
    @State var audioManager = AudioManager()
    @State var pastRecordsManager = PastRecordsManager()

    @State var currentPage: Page = .cupboard

    var body: some View {
        GeometryReader { geom in
            ZStack {
                TapeRecorderView(audioManager: audioManager)
                    .offset(x: currentPage == .recorder ? 0 : -geom.size.width)

                CupboardView(pastRecordsManager: pastRecordsManager)
                    .offset(x: currentPage == .recorder ? geom.size.width : (currentPage == .player ? -geom.size.width : 0))

                Text("Player")
                    .offset(x: currentPage == .player ? 0 : geom.size.width)
            }
            .overlay(alignment: .bottom) {
                // TODO: make these buttons look more like tassles
                HStack {
                    VStack(alignment: .leading) {
                        switch currentPage {
                        case .recorder: EmptyView()
                        case .cupboard:
                            Button("Recorder") {
                                currentPage = .recorder
                            }
                        case .player:
                            Button("Cupboard") {
                                currentPage = .cupboard
                            }
                            Button("Recorder") {
                                currentPage = .recorder
                            }
                        }
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        switch currentPage {
                        case .recorder:
                            Button("Cupboard") {
                                currentPage = .cupboard
                            }
                            Button("Player") { // NOTE: hide if no audio being played
                                currentPage = .player
                            }
                        case .cupboard:
                            Button("Player") {
                                currentPage = .player
                            }
                        case .player: EmptyView()
                        }
                    }
                }
            }
        }
        .animation(.easeInOut, value: currentPage)
    }
}

enum Page: Equatable {
    case recorder
    case cupboard
    case player
}

extension View {
    @inlinable
    public func reverseMask<Mask: View>(
        alignment: Alignment = .center,
        @ViewBuilder _ mask: () -> Mask
    ) -> some View {
        self.mask {
            Rectangle()
                .overlay(alignment: alignment) {
                    mask()
                        .blendMode(.destinationOut)
                }
        }
    }
}
