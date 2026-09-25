import SwiftUI

struct CarListView: View {
    @ObservedObject var carManager: CarManager
    @State private var showingAddCar = false
    
    var body: some View {
        NavigationStack {
            List {
                if carManager.cars.isEmpty {
                    ContentUnavailableView {
                        Label("No Cars Added", systemImage: "car.fill")
                    } description: {
                        Text("Tap the + button to add your first car")
                    }
                } else {
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
                        }
                    }
                    .onDelete { indexSet in
                        carManager.deleteCar(at: indexSet)
                    }
                }
            }
            .navigationTitle("Your Cars")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCar = true
                    } label: {
                        Label("Add Car", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCar) {
                AddCarView(carManager: carManager)
            }
        }
    }
} 