import Foundation

struct FlipRecord: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var carId: UUID
    var carName: String
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
} 