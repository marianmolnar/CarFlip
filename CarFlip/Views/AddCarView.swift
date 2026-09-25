import SwiftUI
import PhotosUI

/// Adds a new car, or edits an existing one when `car` is set.
struct AddCarView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var carManager: CarManager
    let car: Car?

    @State private var carName: String
    @State private var imageData: Data?
    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoadingImage = false
    @FocusState private var nameFocused: Bool

    init(carManager: CarManager, car: Car? = nil) {
        self.carManager = carManager
        self.car = car
        _carName = State(initialValue: car?.name ?? "")
        _imageData = State(initialValue: car?.imageData)
    }

    private var trimmedName: String {
        carName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var previewCar: Car {
        Car(id: car?.id ?? UUID(), name: trimmedName, imageData: imageData)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        CarArtwork(car: previewCar, symbolScale: 0.3)
                            .aspectRatio(4 / 3, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .overlay(alignment: .bottomTrailing) {
                                Label(imageData == nil ? "Add photo" : "Change photo", systemImage: "camera.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(.ultraThinMaterial, in: Capsule())
                                    .padding(14)
                            }
                            .overlay {
                                if isLoadingImage {
                                    ProgressView()
                                        .controlSize(.large)
                                        .tint(.white)
                                }
                            }
                            .shadow(color: .black.opacity(0.15), radius: 16, y: 8)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow("Name")
                        TextField("e.g. Octavia", text: $carName)
                            .font(.badge(20, weight: .bold))
                            .focused($nameFocused)
                            .submitLabel(.done)
                            .onSubmit(save)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }

                    if let car {
                        Button(role: .destructive) {
                            carManager.deleteCar(car)
                            dismiss()
                        } label: {
                            Label("Delete car", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .padding(.top, 8)
                    }
                }
                .padding(20)
            }
            .navigationTitle(car == nil ? "New Car" : "Edit Car")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(trimmedName.isEmpty || isLoadingImage)
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                guard let newItem else { return }
                isLoadingImage = true
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let prepared = Car.preparedImageData(from: data) {
                        withAnimation { imageData = prepared }
                    }
                    isLoadingImage = false
                }
            }
            .onAppear {
                if car == nil { nameFocused = true }
            }
        }
    }

    private func save() {
        guard !trimmedName.isEmpty, !isLoadingImage else { return }
        if var car {
            car.name = trimmedName
            car.imageData = imageData
            carManager.updateCar(car)
        } else {
            carManager.addCar(name: trimmedName, imageData: imageData)
        }
        dismiss()
    }
}
