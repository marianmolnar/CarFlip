import Foundation
import SwiftUI

class CarManager: ObservableObject {
    @Published var cars: [Car] = []
    @Published var flipRecords: [FlipRecord] = []
    
    private let carsKey = "savedCars"
    private let flipRecordsKey = "flipRecords"
    
    init() {
        loadCars()
        loadFlipRecords()
    }
    
    func addCar(name: String, imageData: Data?) {
        let newCar = Car(name: name, imageData: imageData)
        cars.append(newCar)
        saveCars()
    }
    
    func deleteCar(at indexSet: IndexSet) {
        cars.remove(atOffsets: indexSet)
        saveCars()
    }
    
    func recordFlip(car: Car) {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Check if there's already a record for today
        if let existingIndex = flipRecords.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            // Update the existing record instead of adding a new one
            flipRecords[existingIndex] = FlipRecord(date: today, carId: car.id, carName: car.name)
        } else {
            // Create a new record
            let record = FlipRecord(date: today, carId: car.id, carName: car.name)
            flipRecords.append(record)
        }
        
        saveFlipRecords()
    }
    
    func updateFlipRecord(for date: Date, with car: Car) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        
        if let existingIndex = flipRecords.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) }) {
            // Update existing record
            flipRecords[existingIndex] = FlipRecord(date: startOfDay, carId: car.id, carName: car.name)
        } else {
            // Create new record for that day
            let record = FlipRecord(date: startOfDay, carId: car.id, carName: car.name)
            flipRecords.append(record)
        }
        
        saveFlipRecords()
    }
    
    func deleteFlipRecord(for date: Date) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        flipRecords.removeAll { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) }
        saveFlipRecords()
    }
    
    func getRecordsForDate(_ date: Date) -> [FlipRecord] {
        let calendar = Calendar.current
        return flipRecords.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    func getRecordForDate(_ date: Date) -> FlipRecord? {
        let calendar = Calendar.current
        return flipRecords.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    private func saveCars() {
        if let encoded = try? JSONEncoder().encode(cars) {
            UserDefaults.standard.set(encoded, forKey: carsKey)
        }
    }
    
    private func loadCars() {
        if let data = UserDefaults.standard.data(forKey: carsKey),
           let savedCars = try? JSONDecoder().decode([Car].self, from: data) {
            cars = savedCars
        }
    }
    
    private func saveFlipRecords() {
        if let encoded = try? JSONEncoder().encode(flipRecords) {
            UserDefaults.standard.set(encoded, forKey: flipRecordsKey)
        }
    }
    
    private func loadFlipRecords() {
        if let data = UserDefaults.standard.data(forKey: flipRecordsKey),
           let savedRecords = try? JSONDecoder().decode([FlipRecord].self, from: data) {
            flipRecords = savedRecords
        }
    }
} 