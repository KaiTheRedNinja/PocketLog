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
        List {
            Button("Reload records") {
                _ = Task {
                    do {
                        try await pastRecordsManager.populate()
                    } catch {
                        print("Could not populate past records")
                    }
                }
            }
            ForEach($pastRecordsManager.records) { $record in
                VStack(alignment: .leading) {
                    TextField("", text: $record.name)
                        .onSubmit {
                            // a name cannot be left empty
                            if record.name.isEmpty {
                                record.name = record.fileName
                            }
                            pastRecordsManager.save()
                        }
                        .contextMenu {
                            Button("Export") {
                                do {
                                    exportUrl = try FileSystem.export(
                                        file: .recording(name: record.fileName),
                                        newName: record.name + ".m4a"
                                    )
                                } catch {
                                    print("Could not export: \(error)")
                                    exportUrl = nil
                                }
                            }
                        }

                    Text(record.saveDate.displayFormat())
                        .font(.caption)
                }
            }
            .onDelete { indexSet in
                pastRecordsManager.delete(offsets: indexSet)
            }
        }
        .sheet(item: $exportUrl) { url in
            ShareView(activityItems: [url])
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
