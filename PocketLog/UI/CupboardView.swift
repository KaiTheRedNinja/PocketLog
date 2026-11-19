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

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                Color.brown
                    .frame(width: 30)

                Color.brown
                    .brightness(-0.5)
                    .frame(width: 50)
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
