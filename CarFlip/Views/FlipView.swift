import SwiftUI

struct FlipView: View {
    @ObservedObject var carManager: CarManager
    @State private var isFlipping = false
    @State private var selectedCar: Car?
    @State private var flipRotation = 0.0
    @State private var showAlert = false
    @State private var showName = false
    
    var body: some View {
        VStack {
            Spacer()
            
            if carManager.cars.count < 2 {
                ContentUnavailableView {
                    Label("Not Enough Cars", systemImage: "car.2.fill")
                } description: {
                    Text("You need at least 2 cars to flip between them")
                } actions: {
                    NavigationLink(destination: CarListView(carManager: carManager)) {
                        Text("Add Cars")
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                if let car = selectedCar {
                    VStack(spacing: 20) {
                        // Coin-like view with car image
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 250, height: 250)
                                .shadow(radius: 5)
                            
                            if let image = car.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 220, height: 220)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "car.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                    .foregroundColor(.blue)
                            }
                            
                            // Gold coin border
                            Circle()
                                .stroke(Color.yellow.opacity(0.8), lineWidth: 10)
                                .frame(width: 250, height: 250)
                        }
                        .rotation3DEffect(
                            .degrees(flipRotation),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        
                        // Car name shown only after flipping is done
                        if showName {
                            Text(car.name)
                                .font(.title)
                                .bold()
                                .transition(.opacity)
                        }
                    }
                    .padding()
                } else {
                    Text("Tap Flip to choose a car")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    performFlip()
                } label: {
                    Text("FLIP")
                        .font(.title)
                        .bold()
                        .frame(minWidth: 200)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                .disabled(isFlipping)
            }
            
            Spacer()
        }
        .navigationTitle("Car Flip")
        .alert("Car Selected", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            if let car = selectedCar {
                Text("You'll drive \(car.name) today!")
            }
        }
    }
    
    private func performFlip() {
        guard carManager.cars.count >= 2 else { return }
        
        isFlipping = true
        showName = false
        
        // Randomize number of flips between 3 and 7
        let numFlips = Int.random(in: 3...7)
        let totalDuration = Double.random(in: 1.5...2.5) // Random duration between 1.5 and 2.5 seconds
        let flipDuration = totalDuration / Double(numFlips)
        
        // Animate the initial flip
        animateFlips(numFlips: numFlips, flipDuration: flipDuration, currentFlip: 0, availableCars: carManager.cars)
    }
    
    private func animateFlips(numFlips: Int, flipDuration: Double, currentFlip: Int, availableCars: [Car]) {
        // Base case: completed all flips
        if currentFlip >= numFlips {
            // Show the name after all flips are done
            withAnimation(.easeIn(duration: 0.3)) {
                showName = true
            }
            
            // Show alert and reset flipping state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showAlert = true
                isFlipping = false
            }
            return
        }
        
        // Animate the current flip
        withAnimation(.easeInOut(duration: flipDuration / 2)) {
            flipRotation += 180
        }
        
        // After half the flip, update the car
        DispatchQueue.main.asyncAfter(deadline: .now() + flipDuration / 2) {
            // For each flip, choose a random car from all available cars
            // If it's the last flip, exclude the current car to ensure a change
            var carsToChooseFrom = availableCars
            
            if currentFlip == numFlips - 1 && availableCars.count > 1 {
                // For the final flip, ensure we don't pick the same car again
                if let selectedCar = selectedCar {
                    carsToChooseFrom.removeAll { $0.id == selectedCar.id }
                }
            }
            
            // Pick a random car for this flip
            let nextCar = carsToChooseFrom.randomElement() ?? availableCars.first!
            selectedCar = nextCar
            
            // For the final car selection, record it
            if currentFlip == numFlips - 1 {
                carManager.recordFlip(car: nextCar)
            }
            
            // Recurse to animate the next flip
            DispatchQueue.main.asyncAfter(deadline: .now() + flipDuration / 2) {
                animateFlips(numFlips: numFlips, flipDuration: flipDuration, currentFlip: currentFlip + 1, availableCars: availableCars)
            }
        }
    }
} 