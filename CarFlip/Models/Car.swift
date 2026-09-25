import Foundation
import SwiftUI

struct Car: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var imageData: Data?

    private static let imageCache = NSCache<NSString, UIImage>()

    var image: Image? {
        guard let data = imageData else { return nil }
        let key = "\(id.uuidString)-\(data.count)" as NSString
        if let cached = Self.imageCache.object(forKey: key) {
            return Image(uiImage: cached)
        }
        guard let uiImage = UIImage(data: data) else { return nil }
        Self.imageCache.setObject(uiImage, forKey: key)
        return Image(uiImage: uiImage)
    }

    static func == (lhs: Car, rhs: Car) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.imageData == rhs.imageData
    }

    /// Scales a picked photo down so it stays small enough for UserDefaults.
    static func preparedImageData(from data: Data, maxDimension: CGFloat = 1024) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let longest = max(image.size.width, image.size.height)
        let scale = min(1, maxDimension / longest)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.82)
    }
}
