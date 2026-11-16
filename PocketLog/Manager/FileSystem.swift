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
        try data.write(to: directory(for: file))
    }

    static func read<T: Decodable>(type _: T.Type = T.self, from file: File) throws -> T {
        let decoder = JSONDecoder()
        let data = try Data(contentsOf: directory(for: file))
        let value = try decoder.decode(T.self, from: data)
        return value
    }

    static func directory(for file: File) -> URL {
        docsDir().appendingPathComponent(file.path)
    }

    static func docsDir() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

enum File {
    case directory

    var path: String {
        switch self {
        case .directory: "directory.json"
        }
    }
}
