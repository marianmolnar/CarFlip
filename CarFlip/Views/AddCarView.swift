import SwiftUI
import PhotosUI

struct AddCarView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var carManager: CarManager
    @State private var carName = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Car Name", text: $carName)
                
                Section("Car Image") {
                    VStack {
                        if let imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                        } else {
                            Image(systemName: "car.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 100)
                                .foregroundColor(.gray)
                        }
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Label("Select Image", systemImage: "photo")
                        }
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    imageData = data
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
            .navigationTitle("Add Car")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !carName.isEmpty {
                            carManager.addCar(name: carName, imageData: imageData)
                            dismiss()
                        }
                    }
                    .disabled(carName.isEmpty)
                }
            }
        }
    }
} 