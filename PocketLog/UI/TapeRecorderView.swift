//
//  TapeRecorderView.swift
//  PocketLog
//
//  Created by Kai Quan Tay on 17/11/26.
//

import SwiftUI
import Combine
import AVFAudio

let controlsRadius: CGFloat = 20
let controlsHeight: CGFloat = 90
let controlsWidth: CGFloat = 80
let controlsSpacing: CGFloat = 5
let controlsMargins: CGFloat = 10
let controlsTotalHeight: CGFloat = controlsMargins*2 + controlsHeight*4 + controlsSpacing*3
let volumeButtonsCenterOffset: CGFloat = 320

struct TapeRecorderView: View {
    @State var audioManager = AudioManager()

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

            Text("PocketLog Tape Recorder")
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
                        casetteView
                    }

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
            duration = audioManager.audioRecorder?.currentTime ?? 0.0
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
                isDepressed: audioManager.isRecording,
                cornerRadii: .init(bottomTrailing: 0, topTrailing: controlsRadius),
                scaleAnchor: .bottomLeading,
                fillColor: .red,
                icon: "record.circle"
            ) {
                audioManager.beginOrResumeRecording()
            }
            .frame(width: controlsWidth, height: controlsHeight * 2 + controlsSpacing)

            TapeButtonView(
                isDepressed: !audioManager.isRecording,
                cornerRadii: .init(bottomTrailing: 0, topTrailing: 0),
                scaleAnchor: .leading,
                fillColor: .init(white: 0.2),
                icon: "pause.fill"
            ) {
                audioManager.pauseRecording()
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
                audioManager.endRecording()
            }
            .frame(width: controlsWidth, height: controlsHeight)
        }
        .padding([.vertical, .trailing], controlsMargins)
        .padding(.top, volumeButtonsCenterOffset - controlsTotalHeight/2)
    }

    var casetteView: some View {
        HStack(spacing: 0) {
            ZStack {
                // TODO: improve this casette player
                VStack {
                    Spacer()
                    Circle()
                        .frame(width: 50, height: 50)
                    Spacer()
                    Circle()
                        .frame(width: 50, height: 50)
                    Spacer()
                }
                .offset(x: audioManager.currentRecording == nil ? 400 : 0)
                .animation(.easeInOut, value: audioManager.currentRecording == nil)

                Rectangle()
                    .fill(Color.black)
                    .overlay {
                        Rectangle()
                            .fill(Color.black)
                            .opacity(0.1)
                            .padding(10)
                    }
                    .opacity(0.4)
                    .frame(width: 240)
            }

            Rectangle()
                .fill(Color.black)
                .opacity(0.1)
                .frame(width: 40)
        }
        .frame(height: controlsTotalHeight - controlsMargins*2)
        .padding(.top, volumeButtonsCenterOffset - controlsTotalHeight/2 + controlsMargins)
    }

    @ViewBuilder
    var durationView: some View {
        // whether its recording or not
        let recordingStr = if audioManager.audioRecorder == nil {
            "No tape    | "
        } else if audioManager.isRecording {
            "Recording  | "
        } else {
            "Paused     | "
        }
        // the duration
        let durationStr = [
            String(format: "%02d", Int(duration / 3600)),
            String(format: "%02d", Int(duration.truncatingRemainder(dividingBy: 3600) / 60)),
            String(format: "%02d", Int(duration.truncatingRemainder(dividingBy: 60)))
        ].joined(separator: ":") + "." + String(format: "%01d", Int((duration * 10).truncatingRemainder(dividingBy: 10.0)))

        Text(recordingStr + durationStr)
            .monospaced()
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .frame(height: 40, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(white: 0.4))
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

struct TapeButtonView: View {
    var isDepressed: Bool
    var cornerRadii: RectangleCornerRadii
    var scaleAnchor: UnitPoint = .center
    var fillColor: Color
    var icon: String?

    var onRelease: () -> Void

    @State private var fingerDown = false

    var body: some View {
        UnevenRoundedRectangle(cornerRadii: cornerRadii)
            .fill(fillColor)
            .brightness(-0.5)
            .overlay {
                let scale = (fingerDown ? 0.95 : 1) * (isDepressed ? 0.9 : 1)
                let brightness = (fingerDown ? -0.1 : 0.0) + (isDepressed ? -0.1 : 0.0)

                UnevenRoundedRectangle(cornerRadii: cornerRadii)
                    .fill(fillColor)
                    .brightness(brightness)
                    .overlay {
                        if let icon {
                            Image(systemName: icon)
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                        }
                    }
                    .scaleEffect(.init(width: scale, height: scale), anchor: scaleAnchor)
            }
            .animation(.linear(duration: 0.1), value: fingerDown)
            .gesture(press)
    }

    var press: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                fingerDown = true
            }
            .onEnded { finished in
                fingerDown = false
                print("Finished pressing!")
                // if the button is in the up position and has been triggered....
                if !isDepressed {
                    print("Sending release command")
                    onRelease()
                }
            }
    }
}
