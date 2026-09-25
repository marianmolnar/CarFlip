import SwiftUI

enum AppTab: Hashable {
    case garage, flip, history
}

struct MainTabView: View {
    @StateObject private var carManager = CarManager()
    @State private var selectedTab: AppTab = .flip

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Garage", systemImage: "car.2.fill", value: AppTab.garage) {
                CarListView(carManager: carManager)
            }

            Tab("Flip", systemImage: "circle.circle.fill", value: AppTab.flip) {
                FlipView(carManager: carManager, selectedTab: $selectedTab)
            }

            Tab("History", systemImage: "calendar", value: AppTab.history) {
                HistoryView(carManager: carManager)
            }
        }
        .tint(Theme.blue)
    }
}
