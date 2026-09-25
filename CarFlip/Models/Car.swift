import Foundation
import SwiftUI

struct Car: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var imageData: Data?
    
    var image: Image? {
        if let data = imageData, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
    
    static func == (lhs: Car, rhs: Car) -> Bool {
        lhs.id == rhs.id
    }
} 