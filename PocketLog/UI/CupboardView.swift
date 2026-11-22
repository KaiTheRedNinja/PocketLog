//
//  CupboardView.swift
//  PocketLog
//
//  Created by Kai Quan Tay on 19/11/26.
//

import SwiftUI

struct CupboardView: View {
    @State var audioManager = AudioManager()
    @State var pastRecordsManager = PastRecordsManager()
    @State var exportUrl: URL?

    @State private var offset = CGFloat.zero

    @State var selectedRecording: Recording?
    @Binding var currentlyPlaying: Recording?

    @Namespace var namespace

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                Color.brown
                    .brightness(-0.2)
                    .frame(width: 30)

                Color.brown
                    .brightness(-0.5)
                    .frame(width: 50)
                    .overlay {
                        VanishingLines(height: 20, lhsScale: 1.0, rhsScale: 0.8, vOffset: offset)
                            .fill(Color.white)
                            .opacity(0.2)
                    }
                    .overlay {
                        LinearGradient(colors: [.clear, .brown], startPoint: .leading, endPoint: .trailing)
                            .opacity(0.8)
                            .brightness(-0.6)
                    }
                Color.brown
                    .brightness(-0.6)
                Color.brown
                    .brightness(-0.5)
                    .frame(width: 50)
                    .overlay {
                        VanishingLines(height: 20, lhsScale: 0.8, rhsScale: 1.0, vOffset: offset)
                            .fill(Color.white)
                            .opacity(0.2)
                    }
                    .overlay {
                        LinearGradient(colors: [.clear, .brown], startPoint: .trailing, endPoint: .leading)
                            .opacity(0.8)
                            .brightness(-0.6)
                    }

                Color.brown
                    .brightness(-0.2)
                    .frame(width: 30)
            }
            .ignoresSafeArea(.all)

            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 0) {
                    ForEach(pastRecordsManager.records.enumerated(), id: \.element) { (index, record) in
                        let showBarrier: DateCategory? = {
                            let currCategory = record.saveDate.category()
                            if index > 0 {
                                let prevCategory = pastRecordsManager.records[index-1].saveDate.category()
                                if prevCategory != currCategory {
                                    return currCategory
                                } else {
                                    return nil // the prev and next category are the same
                                }
                            }
                            return currCategory
                        }()

                        VStack(spacing: 0) {
                            Spacer()
                                .frame(height: 5)
                            if let showBarrier {
                                Color.brown
                                    .frame(height: 40)
                                    .brightness(-0.3)
                                    .overlay(alignment: .leading) {
                                        Text(showBarrier.description)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 10)
                                    }
                                    .padding(.horizontal, -10)
                            } else {
                                HStack {
                                    Color.brown
                                        .frame(width: 20, height: 10)
                                        .brightness(-0.3)
                                    Spacer()
                                    Color.brown
                                        .frame(width: 20, height: 10)
                                        .brightness(-0.3)
                                }
                                .padding(.horizontal, -10)
                            }
                            Spacer()
                                .frame(height: 5)

                            if selectedRecording != record {
                                casette(for: record)
                                    .zIndex(-100)
                            } else {
                                Spacer()
                                    .frame(height: 60)
                            }
                        }
                        .padding(.horizontal, 35)
                        .onTapGesture {
                            withAnimation {
                                selectedRecording = record
                            }
                        }
                    }

                    Spacer()
                        .frame(height: 80)
                }
            }
            .defaultScrollAnchor(.bottom)
            .onScrollGeometryChange(for: ScrollGeometry.self, of: { $0 }) { oldValue, newValue in
                print("Offset: \(newValue.contentOffset.y) in \(newValue.containerSize)")
                offset = newValue.contentOffset.y
            }

            if let selectedRecording {
                cassetteOverlay(for: selectedRecording)
            }
        }
        .onChange(of: audioManager.currentRecording, initial: true) { _, _ in
            refresh()
        }
        .sheet(item: $exportUrl) { url in
            ShareView(activityItems: [url])
        }
//        List {
//            Button("Reload records") {
//                _ = Task {
//                    do {
//                        try await pastRecordsManager.populate()
//                    } catch {
//                        print("Could not populate past records")
//                    }
//                }
//            }
//            ForEach($pastRecordsManager.records) { $record in
//                VStack(alignment: .leading) {
//                    TextField("", text: $record.name)
//                        .onSubmit {
//                            // a name cannot be left empty
//                            if record.name.isEmpty {
//                                record.name = record.fileName
//                            }
//                            pastRecordsManager.save()
//                        }
//                        .contextMenu {
//                            Button("Export") {
//                                do {
//                                    exportUrl = try FileSystem.export(
//                                        file: .recording(name: record.fileName),
//                                        newName: record.name + ".m4a"
//                                    )
//                                } catch {
//                                    print("Could not export: \(error)")
//                                    exportUrl = nil
//                                }
//                            }
//                        }
//
//                    Text(record.saveDate.displayFormat())
//                        .font(.caption)
//                }
//            }
//            .onDelete { indexSet in
//                pastRecordsManager.delete(offsets: indexSet)
//            }
//        }
//        .sheet(item: $exportUrl) { url in
//            ShareView(activityItems: [url])
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    func casette(for record: Recording) -> some View {
        let screenSize = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.size ?? .zero

        ZStack {
            Color.gray
            HStack(spacing: 0) {
                Color.white
                    .overlay(alignment: .leading) {
                        Text(record.name)
                            .truncationMode(.middle)
                            .lineLimit(1)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 5)
                    }

                Color.green
                    .frame(width: 80)
                    .overlay(alignment: .trailing) {
                        Text(record.saveDate.displayFormat())
                            .font(.caption2)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 3)
                    }
            }
            .padding(8)
        }
        .frame(height: 60)
        .background(alignment: .bottom) {
            GeometryReader { geom in
                let frame = geom.frame(in: .global)
                let offsetFromCenter = frame.minY - screenSize.height / 2

                CassetteView(text: record.name)
                    .matchedGeometryEffect(id: "cassette_\(record.fileName)", in: namespace)
                    .scaleEffect(x: frame.width/cassetteWidth, y: 1, anchor: .bottom)
                    .frame(width: frame.width, height: frame.height, alignment: .bottom)
                    .rotation3DEffect(.degrees(25), axis: (x: 1, y: 0, z: 0), anchor: .bottom)
                    .scaleEffect(y: offsetFromCenter * 0.2 / cassetteHeight, anchor: .bottom)
                    .offset(y: -60)
            }
            .mask {
                Rectangle()
                    .padding(-20)
            }
        }
        .background(alignment: .top) {
            GeometryReader { geom in
                let frame = geom.frame(in: .global)
                let offsetFromCenter = frame.minY - screenSize.height / 2

                CassetteView(text: record.name)
                    .scaleEffect(x: frame.width/cassetteWidth, y: 1, anchor: .top)
                    .frame(width: frame.width, height: frame.height, alignment: .top)
                    .rotation3DEffect(.degrees(-25), axis: (x: 1, y: 0, z: 0), anchor: .top)
                    .scaleEffect(y: -offsetFromCenter * 0.2 / cassetteHeight, anchor: .top)
                    .offset(y: 60)
            }
            .mask {
                Rectangle()
                    .padding(-20)
            }
        }
    }

    func cassetteOverlay(for record: Recording) -> some View {
        ZStack {
            Color.black.opacity(0.5)
                .onTapGesture {
                    withAnimation {
                        selectedRecording = nil
                    }
                }
                .ignoresSafeArea()

            VStack(spacing: 20) {
                CassetteView(text: record.name)
                    .onTapGesture {
                        withAnimation {
                            selectedRecording = nil
                        }
                    }
                    .onChange(of: offset) { _, _ in
                        withAnimation {
                            selectedRecording = nil
                        }
                    }
                    .matchedGeometryEffect(id: "cassette_\(record.fileName)", in: namespace)

                HStack(spacing: 10) {
                    Button {
                        currentlyPlaying = record
                    } label: {
                        Image(systemName: "play")
                            .font(.title)
                            .foregroundStyle(.black)
                    }
                    .padding(.horizontal, 10)

                    Button {
                        do {
                            exportUrl = try FileSystem.export(
                                file: .recording(name: record.fileName),
                                newName: record.name + ".m4a"
                            )
                        } catch {
                            print("Could not export: \(error)")
                            exportUrl = nil
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title)
                            .foregroundStyle(.black)
                    }
                    .padding(.horizontal, 10)

                    Button {
                        withAnimation {
                            selectedRecording = nil
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title)
                            .foregroundStyle(.black)
                    }
                    .padding(.horizontal, 10)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 20)
                .padding(.horizontal, 40)
                .background {
                    RibbonShape(ribbonInsetAbsolute: 10)
                        .fill(Color(red: 0.937, green: 0.917, blue: 0.886))
                        .shadow(radius: 10)
                }
            }
        }
    }

    func refresh() {
        _ = Task {
            do {
                try await pastRecordsManager.populate()
            } catch {
                print("Could not populate past records")
            }
        }
    }
}

struct VanishingLines: Shape {
    /// The height of a single line pair (filled + non filled)
    var height: CGFloat
    /// The duty cycle of the pair - 100% = fully filled, 0% = fully empty, 50% = half filled half not filled
    var dutyCycle: CGFloat = 0.5
    /// How much the left side of the line is scaled by
    var lhsScale: CGFloat
    /// How much the right side of the line is scaled by
    var rhsScale: CGFloat
    /// The vertical offset
    var vOffset: CGFloat

    func path(in rect: CGRect) -> Path {
        if lhsScale <= 0 || rhsScale <= 0 || height <= 0 {
            print("Cannot create a vanishing line with a non-positive scale/height !!!!")
            return .init()
        }

        let visibleSegments = max(rect.height / (height * lhsScale), rect.height / (height * rhsScale)).rounded(.awayFromZero) + 2
        let unscaledOffset = visibleSegments * height / 2 + vOffset.posRemainder(dividingBy: height)
        var lhsCurPos = rect.midY - unscaledOffset * lhsScale
        var rhsCurPos = rect.midY - unscaledOffset * rhsScale

        var path = Path()

        let lhsHeightInterval = height * lhsScale
        let rhsHeightInterval = height * rhsScale

        while lhsCurPos < rect.maxY || rhsCurPos < rect.maxY {
            // draw one rectangle
            path.move(to: .init(x: rect.minX, y: lhsCurPos)) // top left
            path.addLine(to: .init(x: rect.maxX, y: rhsCurPos)) // top right
            path.addLine(to: .init(x: rect.maxX, y: rhsCurPos + rhsHeightInterval * dutyCycle)) // bottom right
            path.addLine(to: .init(x: rect.minX, y: lhsCurPos + lhsHeightInterval * (1 - dutyCycle))) // bottom left
            path.addLine(to: .init(x: rect.minX, y: lhsCurPos)) // close shape
            path.closeSubpath()

            // increase the position by their respective intervals
            lhsCurPos += lhsHeightInterval
            rhsCurPos += rhsHeightInterval
        }

        return path
    }
}

extension BinaryFloatingPoint {
    func posRemainder(dividingBy rhs: Self) -> Self {
        let mod = self.truncatingRemainder(dividingBy: rhs)
        return mod >= 0 ? mod : mod + rhs
    }
}
