import Foundation
import XCTest

final class SharedImageStoreTests: XCTestCase {
    private var temporaryDirectory: URL!
    private var defaults: UserDefaults!
    private var defaultsSuiteName: String!

    override func setUpWithError() throws {
        try super.setUpWithError()
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)

        defaultsSuiteName = "SharedImageStoreTests.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsSuiteName))
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: defaultsSuiteName)
        try? FileManager.default.removeItem(at: temporaryDirectory)
        defaults = nil
        defaultsSuiteName = nil
        temporaryDirectory = nil
        try super.tearDownWithError()
    }

    func testImportCopiesImageAndQueuesItsFilename() throws {
        let sourceURL = temporaryDirectory.appendingPathComponent("qr.PnG!")
        let imageData = Data([0x89, 0x50, 0x4E, 0x47])
        try imageData.write(to: sourceURL)
        let store = makeStore(identifier: "new-image")

        let destinationURL = try store.importImage(at: sourceURL)

        XCTAssertEqual(destinationURL.lastPathComponent, "new-image.png")
        XCTAssertEqual(try Data(contentsOf: destinationURL), imageData)
        XCTAssertEqual(defaults.string(forKey: SharedImageStore.pendingImageKey), "new-image.png")
    }

    func testImportReplacesPreviouslyQueuedImage() throws {
        let sharedImages = temporaryDirectory.appendingPathComponent("shared-images", isDirectory: true)
        try FileManager.default.createDirectory(at: sharedImages, withIntermediateDirectories: true)
        let previousURL = sharedImages.appendingPathComponent("previous.jpg")
        try Data([0x01]).write(to: previousURL)
        defaults.set(previousURL.lastPathComponent, forKey: SharedImageStore.pendingImageKey)

        let sourceURL = temporaryDirectory.appendingPathComponent("replacement.jpeg")
        try Data([0x02]).write(to: sourceURL)

        let destinationURL = try makeStore(identifier: "replacement").importImage(at: sourceURL)

        XCTAssertFalse(FileManager.default.fileExists(atPath: previousURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationURL.path))
        XCTAssertEqual(defaults.string(forKey: SharedImageStore.pendingImageKey), "replacement.jpeg")
    }

    func testImportDoesNotDeleteFileReferencedByUnsafePendingName() throws {
        let outsideURL = temporaryDirectory.appendingPathComponent("outside.png")
        try Data([0x01]).write(to: outsideURL)
        defaults.set("../outside.png", forKey: SharedImageStore.pendingImageKey)

        let sourceURL = temporaryDirectory.appendingPathComponent("incoming.png")
        try Data([0x02]).write(to: sourceURL)

        _ = try makeStore(identifier: "incoming").importImage(at: sourceURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: outsideURL.path))
        XCTAssertEqual(defaults.string(forKey: SharedImageStore.pendingImageKey), "incoming.png")
    }

    private func makeStore(identifier: String) -> SharedImageStore {
        SharedImageStore(
            containerURL: temporaryDirectory,
            defaults: defaults,
            makeIdentifier: { identifier }
        )
    }
}
