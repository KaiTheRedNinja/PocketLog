import SwiftUI
import Playgrounds

struct ContentView: View {
    @State var audioManager = AudioManager()
    @State var pastRecordsManager = PastRecordsManager()

    @State var currentPage: Page = .player
    @State var currentlyPlaying: Recording? = nil

    var body: some View {
        GeometryReader { geom in
            ZStack {
                TapeRecorderView(audioManager: audioManager)
                    .offset(x: currentPage == .recorder ? 0 : -geom.size.width)

                CupboardView(audioManager: audioManager, pastRecordsManager: pastRecordsManager, currentlyPlaying: $currentlyPlaying)
                    .offset(x: currentPage == .recorder ? geom.size.width : (currentPage == .player ? -geom.size.width : 0))

                TapePlayerView(recording: $currentlyPlaying)
                    .offset(x: currentPage == .player ? 0 : geom.size.width)
            }
            .onChange(of: currentlyPlaying) { oldValue, newValue in
                if newValue != nil {
                    currentPage = .player
                }
            }
            .overlay(alignment: .bottom) {
                // TODO: make these buttons look more like tassles
                HStack {
                    VStack(alignment: .leading) {
                        switch currentPage {
                        case .recorder: EmptyView()
                        case .cupboard:
                            tagButton(page: .recorder)
                        case .player:
                            tagButton(page: .cupboard)
                            tagButton(page: .recorder)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        switch currentPage {
                        case .recorder:
                            tagButton(page: .cupboard)
                            tagButton(page: .player) // NOTE: hide if no audio being played
                        case .cupboard:
                            tagButton(page: .player)
                        case .player: EmptyView()
                        }
                    }
                }
            }
        }
        .animation(.easeInOut, value: currentPage)
        .task {
            await audioManager.requestRecordingPermission()
        }
    }

    func tagButton(page: Page) -> some View {
        Button {
            currentPage = page
        } label: {
            Text(page.name)
                .font(.system(.title3, design: .serif).italic())
                .foregroundStyle(.black)
                .padding(.vertical, 5)
                .padding(.horizontal, 20)
                .background {
                    RibbonShape(ribbonInset: 0.2)
                        .fill(Color(red: 0.937, green: 0.917, blue: 0.886))
                        .shadow(radius: 10)
                }
        }
        .padding(.horizontal, -10)
        .buttonStyle(.plain)
    }
}

enum Page: Equatable {
    case recorder
    case cupboard
    case player

    var name: String {
        switch self {
        case .recorder: "Recorder"
        case .cupboard: "Cupboard"
        case .player: "Player"
        }
    }
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

struct RibbonShape: Shape {
    /// The inset of the ribbon, relative to the height of the ribbon. Defaults to 0.5.
    var ribbonInset: CGFloat?
    /// The inset of the ribbon, as an absolute value.
    var ribbonInsetAbsolute: CGFloat?

    init(ribbonInset: CGFloat) {
        self.ribbonInset = ribbonInset
        self.ribbonInsetAbsolute = nil
    }
    init(ribbonInsetAbsolute: CGFloat) {
        self.ribbonInset = nil
        self.ribbonInsetAbsolute = ribbonInsetAbsolute
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = if let ribbonInset { rect.height * ribbonInset } else { ribbonInsetAbsolute! }
        path.move(to: rect.origin)
        // right side
        path.addLine(to: .init(x: rect.maxX, y: rect.minY))
        path.addLine(to: .init(x: rect.maxX - inset, y: rect.midY))
        path.addLine(to: .init(x: rect.maxX, y: rect.maxY))
        // left side
        path.addLine(to: .init(x: rect.minX, y: rect.maxY))
        path.addLine(to: .init(x: rect.minX + inset, y: rect.midY))
        path.addLine(to: .init(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
