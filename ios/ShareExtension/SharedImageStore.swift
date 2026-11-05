import Foundation

struct SharedImageStore {
    static let pendingImageKey = "pendingSharedImageFilename"

    let containerURL: URL
    let defaults: UserDefaults
    var fileManager: FileManager = .default
    var makeIdentifier: () -> String = { UUID().uuidString }

    @discardableResult
    func importImage(at sourceURL: URL) throws -> URL {
        let directory = containerURL.appendingPathComponent("shared-images", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let sourceExtension = sourceURL.pathExtension
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
        let fileName = [makeIdentifier(), sourceExtension.isEmpty ? nil : sourceExtension]
            .compactMap { $0 }
            .joined(separator: ".")
        let destinationURL = directory.appendingPathComponent(fileName)

        try fileManager.copyItem(at: sourceURL, to: destinationURL)

        if let previousName = defaults.string(forKey: Self.pendingImageKey),
           previousName == (previousName as NSString).lastPathComponent,
           previousName != fileName {
            try? fileManager.removeItem(at: directory.appendingPathComponent(previousName))
        }

        defaults.set(fileName, forKey: Self.pendingImageKey)
        return destinationURL
    }
}
