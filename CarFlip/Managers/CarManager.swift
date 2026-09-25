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

    func updateCar(_ car: Car) {
        guard let index = cars.firstIndex(where: { $0.id == car.id }) else { return }
        cars[index] = car
        saveCars()

        // Keep the denormalized name in history in sync
        for i in flipRecords.indices where flipRecords[i].carId == car.id {
            flipRecords[i].carName = car.name
        }
        saveFlipRecords()
    }

    func deleteCar(at indexSet: IndexSet) {
        cars.remove(atOffsets: indexSet)
        saveCars()
    }

    func deleteCar(_ car: Car) {
        cars.removeAll { $0.id == car.id }
        saveCars()
    }

    func car(withId id: UUID) -> Car? {
        cars.first { $0.id == id }
    }

    func driveCount(for car: Car) -> Int {
        flipRecords.filter { $0.carId == car.id }.count
    }

    func recordFlip(car: Car) {
        updateFlipRecord(for: Date(), with: car)
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
