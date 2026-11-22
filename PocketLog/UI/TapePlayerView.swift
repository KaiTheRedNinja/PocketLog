//
//  TapePlayerView.swift
//  PocketLog
//
//  Created by Kai Quan Tay on 22/11/26.
//

import SwiftUI
import Combine
import AVFAudio

struct TapePlayerView: View {
    @Binding var recording: Recording?
    @Binding var currentPage: Page

    @State var playbackManager = AudioPlayback(recording: nil)

    @State var timer = Timer.publish(every: 0.05, on: .main, in: .default).autoconnect()
    @State var duration: TimeInterval = 0

    // possible interface plan?
    // left side, next to volume buttons
    // - start/resume recording (double size?)
    // - pause recording
    // - eject

    // UI improvements that I can do:
    // - add an LED effect to the recording button
    // - add duration indicator
    // - make the casette look like a casette

    var body: some View {
        GeometryReader { geom in ZStack {
            // background
            backgroundView

            Text("PocketLog Tape Player")
                .italic()
                .bold()
                .foregroundStyle(Color(white: 0.2))
                .padding(.leading, 40)
                .padding(.top, 80)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            VStack(spacing: 20) {
                // the casette player looking thing
                cassetteView
                    .zIndex(100)

                // controls
                controlsView

                // the duration "LCD"
                durationView

                // the grills at the bottom
                grillsView
            }
            .ignoresSafeArea(.all)
        }.frame(width: geom.size.width, height: geom.size.height)}
        .clipped()
        .ignoresSafeArea(.all)
        .onReceive(timer) { _ in
            duration = playbackManager.player?.currentTime ?? 0.0
        }
        .onChange(of: recording) { _, newValue in
            if let newValue {
                playbackManager.load(recording: newValue, playAfterLoad: true)
            } else {
                playbackManager.eject()
                recording = nil
                currentPage = .cupboard
            }
        }
    }

    var backgroundView: some View {
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
    }

    var controlsView: some View {
        HStack(alignment: .top, spacing: 5) {
            TapeButtonView(
                isDepressed: playbackManager.isPlaying,
                cornerRadii: .init(topLeading: controlsRadius, bottomLeading: controlsRadius),
                scaleAnchor: .trailing,
                fillColor: .red,
                icon: "play",
                activeLed: true
            ) {
                playbackManager.beginOrResume()
            }
            .frame(width: controlsWidth, height: controlsWidth)

            TapeButtonView(
                isDepressed: !playbackManager.isPlaying,
                cornerRadii: .init(),
                scaleAnchor: .center,
                fillColor: .init(white: 0.2),
                icon: "pause.fill"
            ) {
                playbackManager.pause()
            }
            .frame(width: controlsWidth, height: controlsWidth)

            TapeButtonView(
                isDepressed: false, // eject button will never be depressed
                cornerRadii: .init(bottomTrailing: controlsRadius, topTrailing: controlsRadius),
                scaleAnchor: .leading,
                fillColor: .init(white: 0.2),
                icon: "eject.fill"
            ) {
                // ending the recording will also remove the `currentRecording`
                playbackManager.eject()
                recording = nil
                currentPage = .cupboard
            }
            .frame(width: controlsWidth, height: controlsWidth)
        }
        .padding(.all, controlsMargins)
        .background {
            RoundedRectangle(cornerRadius: controlsRadius+controlsMargins)
                .fill(Color(red: 0.655, green: 0.631, blue: 0.624))
                .brightness(-0.2)
        }
    }

    @ViewBuilder
    var cassetteView: some View {
        let screenSize = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.size ?? .zero
        let scale = (screenSize.width - 80) / cassetteWidth

        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.black)
                .padding(.trailing, -10)
                .opacity(0.1)
                .zIndex(-1)

            ZStack {
                CassetteView(phase: duration)
                    .offset(x: playbackManager.player == nil ? -500 : 0)
                    .background {
                        Rectangle()
                            .fill(Color.black)
                            .overlay {
                                Rectangle()
                                    .fill(Color.black)
                                    .opacity(0.1)
                                    .padding(10)
                            }
                            .opacity(0.4)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay {
                                Text("Load a tape from\nthe cupboard")
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.black)
                            }
                    }
                    .scaleEffect(x: scale, y: scale)

                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(white: 0.6))
                    .stroke(Color(white: 0.4), lineWidth: 2)
                    .padding(1)
                    .frame(width: cassetteWidth * scale, height: cassetteHeight * scale)
                    .reverseMask {
                        Rectangle()
                            .padding(40)
                    }
                    .overlay {
                        Rectangle()
                            .stroke(Color(white: 0.4), lineWidth: 2)
                            .padding(40)
                    }
                    .rotation3DEffect(
                        .degrees(playbackManager.player == nil ? 45 : 0),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: .trailing,
                        perspective: 0.3
                    )
            }
            .frame(width: cassetteWidth * scale, height: cassetteHeight * scale)
            .animation(.easeInOut, value: playbackManager.player == nil)

            Rectangle()
                .fill(Color.clear)
        }
        .frame(height: cassetteHeight * scale)
        .padding(.top, volumeButtonsCenterOffset - controlsTotalHeight/2 + controlsMargins)
    }

    @ViewBuilder
    var durationView: some View {
        // the duration
        let durationStr = [
            String(format: "%02d", Int(duration / 3600)),
            String(format: "%02d", Int(duration.truncatingRemainder(dividingBy: 3600) / 60)),
            String(format: "%02d", Int(duration.truncatingRemainder(dividingBy: 60)))
        ].joined(separator: ":") + "." + String(format: "%01d", Int((duration * 10).truncatingRemainder(dividingBy: 10.0)))

        let totalDuration = playbackManager.player?.duration ?? 0.0
        let totalDurationStr = [
            String(format: "%02d", Int(totalDuration / 3600)),
            String(format: "%02d", Int(totalDuration.truncatingRemainder(dividingBy: 3600) / 60)),
            String(format: "%02d", Int(totalDuration.truncatingRemainder(dividingBy: 60)))
        ].joined(separator: ":") + "." + String(format: "%01d", Int((totalDuration * 10).truncatingRemainder(dividingBy: 10.0)))

        HStack {
            Text(durationStr)
            Spacer()
            Text(" / ")
            Spacer()
            Text(totalDurationStr)
        }
        .foregroundStyle(.black)
        .monospaced()
        .bold()
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .frame(height: 40, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(white: 0.45))
                .shadow(radius: 6)
        }
        .padding(.horizontal, 40)
    }

    var grillsView: some View {
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
            .padding([.horizontal, .bottom], 40)
    }
}
