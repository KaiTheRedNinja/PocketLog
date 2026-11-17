import SwiftUI
import Playgrounds

struct ContentView: View {
    @State var audioManager = AudioManager()
    @State var pastRecordsManager = PastRecordsManager()

    @State var exportUrl: URL?

    // possible interface plan?
    // left side, next to volume buttons
    // - start/resume recording (double size?
    // - pause recording
    // - eject

    var body: some View {
        ZStack {
            // background
            ZStack {
                let fillGradient = LinearGradient(
                    colors: [
                        // taken by sampling random spots on an image of a casette player :P
                        Color(red: 0.722, green: 0.718, blue: 0.710),
                        Color(red: 0.655, green: 0.631, blue: 0.624),
                        Color(red: 0.521, green: 0.518, blue: 0.521)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // TODO: consider splitting up this border into 4 segments to shade each individually
                // border
                Rectangle()
                    .fill(fillGradient)
                    .brightness(-0.1)

                // main body
                RoundedRectangle(cornerRadius: 44)
                    .fill(fillGradient)
                    .padding(20)
            }
            .ignoresSafeArea(.all)

            // controls
            let controlsRadius: CGFloat = 20
            let controlsHeight: CGFloat = 90
            let controlsWidth: CGFloat = 80
            let controlsSpacing: CGFloat = 5
            let controlsMargins: CGFloat = 10
            let controlsTotalHeight: CGFloat = controlsMargins*2 + controlsHeight*4 + controlsSpacing*3
            let volumeButtonsCenterOffset: CGFloat = 255
            VStack(alignment: .leading, spacing: 5) {
                UnevenRoundedRectangle(cornerRadii: .init(bottomTrailing: 0, topTrailing: controlsRadius))
                    .fill(.red)
                    .overlay {
                        Image(systemName: "record.circle")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                    }
                    .frame(width: controlsWidth, height: controlsHeight * 2 + controlsSpacing)

                UnevenRoundedRectangle(cornerRadii: .init(bottomTrailing: 0, topTrailing: 0))
                    .fill(.black)
                    .overlay {
                        Image(systemName: "pause.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                    }
                    .frame(width: controlsWidth, height: controlsHeight)

                UnevenRoundedRectangle(cornerRadii: .init(bottomTrailing: controlsRadius, topTrailing: 0))
                    .fill(.black)
                    .overlay {
                        Image(systemName: "eject.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                    }
                    .frame(width: controlsWidth, height: controlsHeight)
            }
            .padding([.vertical, .trailing], controlsMargins)
            .background {
                UnevenRoundedRectangle(cornerRadii: .init(bottomTrailing: controlsRadius+controlsMargins, topTrailing: controlsRadius+controlsMargins))
                    .fill(.gray)
            }
            .padding(.top, volumeButtonsCenterOffset - controlsTotalHeight/2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // the casette player looking thing
            HStack(spacing: 0) {
                // TODO: add the casette player underneath it
                Rectangle()
                    .fill(Color.black)
                    .overlay {
                        Rectangle()
                            .fill(Color.black)
                            .opacity(0.1)
                            .padding(10)
                    }
                    .opacity(0.4)
                    .frame(width: 240, height: 375)

                Rectangle()
                    .fill(Color.black)
                    .opacity(0.1)
                    .frame(width: 40, height: 375)
            }
            .padding(.top, volumeButtonsCenterOffset - 375/2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            // the grills at the bottom
            UnevenRoundedRectangle(cornerRadii: .init(bottomLeading: 24, bottomTrailing: 24))
                .fill(Color(white: 0.3))
                .overlay {
                    Circle()
                        .fill(Color(white: 0.1))
                        .frame(width: 200, height: 200)
                }
                .mask {
                    VStack {
                        ForEach(0..<15) { _ in
                            HStack {
                                ForEach(0..<13) { _ in
                                    Circle()
                                        .frame(width: 15, height: 15)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            }
                        }
                    }
                }
                .frame(height: 300)
                .padding(40)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(.all, edges: .bottom)
        }
    }
}
