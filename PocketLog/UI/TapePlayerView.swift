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

            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    // controls
                    controlsView

                    Spacer()

                    // the casette player looking thing
                    cassetteView
                }
                .zIndex(100)

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
                .reverseMask(alignment: .topLeading) {
                    UnevenRoundedRectangle(cornerRadii: .init(bottomTrailing: controlsRadius+controlsMargins, topTrailing: controlsRadius+controlsMargins))
                        .frame(width: controlsWidth + 10, height: controlsTotalHeight)
                        .padding(.top, volumeButtonsCenterOffset - controlsTotalHeight/2)
                }
        }
    }

    var controlsView: some View {
        VStack(alignment: .leading, spacing: 5) {
            TapeButtonView(
                isDepressed: playbackManager.isPlaying,
                cornerRadii: .init(bottomTrailing: 0, topTrailing: controlsRadius),
                scaleAnchor: .bottomLeading,
                fillColor: .red,
                icon: "play",
                activeLed: true
            ) {
                playbackManager.beginOrResume()
            }
            .frame(width: controlsWidth, height: controlsHeight * 2 + controlsSpacing)

            TapeButtonView(
                isDepressed: !playbackManager.isPlaying,
                cornerRadii: .init(bottomTrailing: 0, topTrailing: 0),
                scaleAnchor: .leading,
                fillColor: .init(white: 0.2),
                icon: "pause.fill"
            ) {
                playbackManager.pause()
            }
            .frame(width: controlsWidth, height: controlsHeight)

            TapeButtonView(
                isDepressed: false, // eject button will never be depressed
                cornerRadii: .init(bottomTrailing: controlsRadius, topTrailing: 0),
                scaleAnchor: .topLeading,
                fillColor: .init(white: 0.2),
                icon: "eject.fill"
            ) {
                // ending the recording will also remove the `currentRecording`
                playbackManager.eject()
            }
            .frame(width: controlsWidth, height: controlsHeight)
        }
        .padding([.vertical, .trailing], controlsMargins)
        .padding(.top, volumeButtonsCenterOffset - controlsTotalHeight/2)
    }

    var cassetteView: some View {
        HStack(spacing: 0) {
            ZStack {
                // NOTE: this cassette is actually horizontal in orientation, just rotated 90 degrees to face the correct way.
                CassetteView(phase: duration)
                    .rotationEffect(.degrees(90), anchor: .center)
                    .offset(x: playbackManager.player == nil ? 400 : 0)
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
                            .frame(width: cassetteHeight, height: cassetteWidth)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(white: 0.6))
                    .stroke(Color(white: 0.4), lineWidth: 2)
                    .padding(1)
                    .reverseMask {
                        Rectangle()
                            .padding(40)
                    }
                    .overlay {
                        Rectangle()
                            .stroke(Color(white: 0.4), lineWidth: 2)
                            .padding(40)
                    }
                    .frame(width: cassetteHeight, height: cassetteWidth)
                    .rotation3DEffect(
                        .degrees(playbackManager.player == nil ? -45 : 0),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: .leading,
                        perspective: 0.5
                    )
            }
            .animation(.easeInOut, value: playbackManager.player == nil)
            .frame(width: cassetteHeight)

            Rectangle()
                .fill(Color.black)
                .padding(.leading, -10)
                .opacity(0.1)
                .frame(width: 40)
                .zIndex(-1)
        }
        .frame(height: controlsTotalHeight - controlsMargins*2)
        .padding(.top, volumeButtonsCenterOffset - controlsTotalHeight/2 + controlsMargins)
    }

    @ViewBuilder
    var durationView: some View {
        // whether its recording or not
        let recordingStr = if playbackManager.player == nil {
            "No tape"
        } else if playbackManager.isPlaying {
            "Playing"
        } else {
            "Paused"
        }
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
