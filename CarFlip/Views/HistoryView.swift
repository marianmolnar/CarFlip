import SwiftUI

struct HistoryView: View {
    @ObservedObject var carManager: CarManager
    @State private var selectedDate = Date()
    @State private var showingEditSheet = false
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
                
                if let record = carManager.getRecordForDate(selectedDate) {
                    RecordDetailView(record: record, carManager: carManager, selectedDate: $selectedDate)
                } else {
                    ContentUnavailableView {
                        Label("No Car Selected", systemImage: "calendar")
                    } description: {
                        Text("No car has been selected for this date")
                    } actions: {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Text("Select a Car")
                                .frame(minWidth: 150)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("History")
            .sheet(isPresented: $showingEditSheet) {
                EditRecordView(carManager: carManager, date: selectedDate)
            }
        }
    }
}

struct RecordDetailView: View {
    let record: FlipRecord
    let carManager: CarManager
    @Binding var selectedDate: Date
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Spacer()
                
                // Edit and Delete buttons
                Button {
                    showingEditSheet = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .padding(.horizontal)
                
                Button {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                        .foregroundColor(.red)
                }
                .padding(.horizontal)
            }
            .padding(.top)
            
            Spacer()
            
            // Car info
            VStack(spacing: 20) {
                Image(systemName: "car.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                    .foregroundColor(.blue)
                
                Text(record.carName)
                    .font(.title)
                    .bold()
                
                Text(record.formattedDate)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
            )
            .padding()
            
            Spacer()
        }
        .sheet(isPresented: $showingEditSheet) {
            EditRecordView(carManager: carManager, date: selectedDate)
        }
        .alert("Delete Record", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                carManager.deleteFlipRecord(for: selectedDate)
            }
        } message: {
            Text("Are you sure you want to delete this record? This cannot be undone.")
        }
    }
}

struct EditRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var carManager: CarManager
    let date: Date
    @State private var selectedCarId: UUID?
    
    var body: some View {
        NavigationStack {
            VStack {
                if carManager.cars.isEmpty {
                    ContentUnavailableView {
                        Label("No Cars Available", systemImage: "car.fill")
                    } description: {
                        Text("Add cars in the Cars tab first")
                    }
                } else {
                    List {
                        ForEach(carManager.cars) { car in
                            HStack {
                                if let image = car.image {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                } else {
                                    Image(systemName: "car.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.gray)
                                        .padding(5)
                                }
                                
                                Text(car.name)
                                    .font(.headline)
                                
                                Spacer()
                                
                                if selectedCarId == car.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedCarId = car.id
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Car for \(formatDate(date))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let carId = selectedCarId, let car = carManager.cars.first(where: { $0.id == carId }) {
                            carManager.updateFlipRecord(for: date, with: car)
                            dismiss()
                        }
                    }
                    .disabled(selectedCarId == nil)
                }
            }
            .onAppear {
                // Pre-select the current car if one exists
                if let record = carManager.getRecordForDate(date) {
                    selectedCarId = record.carId
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
} 