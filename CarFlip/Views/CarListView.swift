import SwiftUI

struct CarListView: View {
    @ObservedObject var carManager: CarManager
    @State private var editorTarget: EditorTarget?
    @State private var carPendingDeletion: Car?

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow(carManager.cars.count == 1 ? "1 car" : "\(carManager.cars.count) cars")
                        Text("Garage")
                            .font(.badge(34))
                    }

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(carManager.cars) { car in
                            Button {
                                editorTarget = .edit(car)
                            } label: {
                                CarCard(car: car, drives: carManager.driveCount(for: car))
                            }
                            .buttonStyle(CardButtonStyle())
                            .contextMenu {
                                Button("Edit", systemImage: "pencil") {
                                    editorTarget = .edit(car)
                                }
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    carPendingDeletion = car
                                }
                            }
                        }

                        Button {
                            editorTarget = .new
                        } label: {
                            AddCarCard(isFirst: carManager.cars.isEmpty)
                        }
                        .buttonStyle(CardButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .sheet(item: $editorTarget) { target in
            AddCarView(carManager: carManager, car: target.car)
        }
        .confirmationDialog(
            "Delete \(carPendingDeletion?.name ?? "car")?",
            isPresented: Binding(
                get: { carPendingDeletion != nil },
                set: { if !$0 { carPendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let car = carPendingDeletion {
                    withAnimation(.snappy) { carManager.deleteCar(car) }
                }
            }
        } message: {
            Text("Past days in History will keep its name.")
        }
    }
}

private enum EditorTarget: Identifiable {
    case new
    case edit(Car)

    var id: String {
        switch self {
        case .new: "new"
        case .edit(let car): car.id.uuidString
        }
    }

    var car: Car? {
        if case .edit(let car) = self { return car }
        return nil
    }
}

private struct CarCard: View {
    let car: Car
    let drives: Int

    var body: some View {
        CarArtwork(car: car)
            .aspectRatio(0.78, contentMode: .fit)
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(car.name)
                        .font(.badge(16, weight: .bold))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(drives == 1 ? "1 day driven" : "\(drives) days driven")
                        .font(.caption.weight(.medium))
                        .opacity(0.8)
                }
                .foregroundStyle(.white)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(colors: [.black.opacity(0.65), .clear], startPoint: .bottom, endPoint: .top)
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 14, y: 8)
    }
}

private struct AddCarCard: View {
    let isFirst: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.ultraThinMaterial)
            .aspectRatio(0.78, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Theme.blue.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
            )
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(Theme.brandGradient, in: Circle())
                        .shadow(color: Theme.violet.opacity(0.4), radius: 10, y: 5)
                    Text(isFirst ? "Add your\nfirst car" : "Add car")
                        .font(.badge(13, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                }
            }
    }
}

private struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    CarListView(carManager: CarManager())
}
