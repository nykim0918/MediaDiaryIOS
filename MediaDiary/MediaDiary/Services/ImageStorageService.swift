//
//  ImageStorageService.swift
//  MediaDiary
//

import Foundation
import UIKit

class ImageStorageService {
    static let shared = ImageStorageService()
    private init() {
        // Create ReviewImages directory if needed
        let dir = reviewImagesDir
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    private var reviewImagesDir: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ReviewImages", isDirectory: true)
    }

    /// Save a UIImage to disk and return the filename (UUID.jpg)
    @discardableResult
    func save(_ image: UIImage, compressionQuality: CGFloat = 0.82) -> String? {
        guard let data = image.jpegData(compressionQuality: compressionQuality) else { return nil }
        let filename = "\(UUID().uuidString).jpg"
        let url = reviewImagesDir.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            return filename
        } catch {
            print("ImageStorageService: save failed \(error)")
            return nil
        }
    }

    /// Load a UIImage from disk by filename
    func load(filename: String) -> UIImage? {
        let url = reviewImagesDir.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Delete an image file from disk
    func delete(filename: String) {
        let url = reviewImagesDir.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }
}
