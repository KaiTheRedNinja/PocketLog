//
//  FileSystem.swift
//  PocketLog
//
//  Created by Kai Quan Tay on 16/11/26.
//

import Foundation

enum FileSystem {
    static func write<T: Encodable>(value: T, to file: File) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        try data.write(to: path(for: file))
    }

    static func read<T: Decodable>(type _: T.Type = T.self, from file: File) throws -> T {
        let decoder = JSONDecoder()
        let data = try Data(contentsOf: path(for: file))
        let value = try decoder.decode(T.self, from: data)
        return value
    }

    static func delete(_ file: File) throws {
        try FileManager.default.removeItem(at: path(for: file))
    }

    static func create(dir: File) throws {
        try FileManager.default.createDirectory(at: path(for: dir), withIntermediateDirectories: true)
    }

    static func contents(of dir: File) throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: path(for: dir).path())
    }

    /// Prepares a document and puts it in the temporary directory under a new name
    static func export(file: File, newName: String) throws -> URL {
        let sourcePath = path(for: file)
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let exportsDirectory = temporaryDirectory.appending(path: "exports", directoryHint: .isDirectory)
        let destinationUrl = exportsDirectory.appendingPathComponent(newName)
        // create the exports directory
        try FileManager.default.createDirectory(at: exportsDirectory, withIntermediateDirectories: true)
        // remove anything that is already there. If it fails, no issue, probably because the file wasn't there to begin with.
        try? FileManager.default.removeItem(at: destinationUrl)
        // copy from file in file system to export directory
        try FileManager.default.copyItem(at: sourcePath, to: destinationUrl)
        // update the properties. This can fail without affecting the rest of the function
        do  {
            let attributes = try FileManager.default.attributesOfItem(atPath: sourcePath.path())
            if let creationDate = attributes[.creationDate] {
                try FileManager.default.setAttributes([.creationDate: creationDate], ofItemAtPath: destinationUrl.path())
            }
        } catch {
            print("Could not copy attributes: \(error.localizedDescription)")
        }
        return destinationUrl
    }

    static func path(for file: File) -> URL {
        docsDir().appendingPathComponent(file.path)
    }

    static func docsDir() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

// from https://medium.com/over-engineering/monitoring-a-folder-for-changes-in-ios-dc3f8614f902
class FolderMonitor {
    /// A file descriptor for the monitored directory.
    private var monitoredFolderFileDescriptor: CInt = -1
    /// A dispatch source to monitor a file descriptor created from the directory.
    private var folderMonitorSource: DispatchSourceFileSystemObject?
    /// A dispatch queue used for sending file changes in the directory.
    private let folderMonitorQueue = DispatchQueue(label: "FolderMonitorQueue", attributes: .concurrent)

    let url: URL
    var folderDidChange: (() -> Void)?

    init(url: URL, folderDidChange: (() -> Void)? = nil) {
        self.url = url
        self.folderDidChange = folderDidChange
    }

    func startMonitoring() {
        guard folderMonitorSource == nil && monitoredFolderFileDescriptor == -1 else {
            return
        }
        // Open the folder referenced by URL for monitoring only.
        monitoredFolderFileDescriptor = open(url.path, O_EVTONLY)

        // Define a dispatch source monitoring the folder for additions, deletions, and renamings.
        folderMonitorSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: monitoredFolderFileDescriptor,
            eventMask: .write,
            queue: folderMonitorQueue
        )

        // Define the block to call when a file change is detected.
        folderMonitorSource?.setEventHandler { [weak self] in
            self?.folderDidChange?()
        }

        // Define a cancel handler to ensure the directory is closed when the source is cancelled.
        folderMonitorSource?.setCancelHandler { [weak self] in
            guard let self = self else { return }
            close(self.monitoredFolderFileDescriptor)
            self.monitoredFolderFileDescriptor = -1
            self.folderMonitorSource = nil
        }

        // Start monitoring the directory via the source.
        folderMonitorSource?.resume()
    }

    func stopMonitoring() {
        folderMonitorSource?.cancel()
    }
}

enum File {
    case root
    case recordingsDir
    case recording(name: String)
    case renames
    case arbitrary(path: String)

    var path: String {
        switch self {
        case .root: ""
        case .recordingsDir: "recordings/"
        case .recording(let name): "recordings/\(name)"
        case .renames: "renames.json"
        case .arbitrary(let path): path
        }
    }
}
