//
//  CupboardView.swift
//  PocketLog
//
//  Created by Kai Quan Tay on 19/11/26.
//

import SwiftUI

struct CupboardView: View {
    @State var pastRecordsManager = PastRecordsManager()
    @State var exportUrl: URL?

    @State private var offset = CGFloat.zero

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                Color.brown
                    .frame(width: 30)

                Color.brown
                    .brightness(-0.5)
                    .frame(width: 50)
                    .overlay {
                        VanishingLines(height: 20, lhsScale: 1.2, rhsScale: 1, vOffset: 0)
                            .fill(Color.white)
                            .opacity(0.2)
                    }
                Color.brown
                    .brightness(-0.8)
                Color.brown
                    .brightness(-0.5)
                    .frame(width: 50)

                Color.brown
                    .frame(width: 30)
            }
            .ignoresSafeArea(.all)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(pastRecordsManager.records) { record in
                        VStack(spacing: 0) {
                            casette(for: record)
                            .frame(height: 60)

                            Spacer()
                                .frame(height: 5)
                            Color.brown
                                .frame(height: 10)
                                .brightness(-0.2)
                                .padding(.horizontal, -10)
                            Spacer()
                                .frame(height: 5)
                        }
                        .padding(.horizontal, 35)
                    }

                    Button("refresh") {
                        _ = Task {
                            do {
                                try await pastRecordsManager.populate()
                            } catch {
                                print("Could not populate past records")
                            }
                        }
                    }
                }
            }
            .defaultScrollAnchor(.bottom)
            .onScrollGeometryChange(for: ScrollGeometry.self, of: { $0 }) { oldValue, newValue in
                print("Offset: \(newValue.contentOffset.y) in \(newValue.containerSize)")
            }
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

    func casette(for record: Recording) -> some View {
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
    }
}

struct VanishingLines: Shape {
    /// The height of a single line
    var height: CGFloat
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
        // um idk how to do the parallax error I would like to do... ima start with assuming the top of the shape is where they're flat

        var lhsCurPos = rect.minY
        var rhsCurPos = rect.minY

        var path = Path()

        let lhsHeightInterval = height * lhsScale
        let rhsHeightInterval = height * rhsScale

        while lhsCurPos < rect.maxY || rhsCurPos < rect.maxY {
            // draw one rectangle
            path.move(to: .init(x: rect.minX, y: lhsCurPos)) // top left
            path.addLine(to: .init(x: rect.maxX, y: rhsCurPos)) // top right
            path.addLine(to: .init(x: rect.maxX, y: rhsCurPos + rhsHeightInterval)) // bottom right
            path.addLine(to: .init(x: rect.minX, y: lhsCurPos + lhsHeightInterval)) // bottom left
            path.addLine(to: .init(x: rect.minX, y: lhsCurPos)) // close shape
            path.closeSubpath()

            // increase the position by 2x of their respective intervals
            lhsCurPos += lhsHeightInterval * 2
            rhsCurPos += rhsHeightInterval * 2
        }

        return path
    }
}
