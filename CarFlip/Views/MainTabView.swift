import SwiftUI

struct MainTabView: View {
    @StateObject private var carManager = CarManager()
    
    var body: some View {
        TabView {
            CarListView(carManager: carManager)
                .tabItem {
                    Label("Cars", systemImage: "car.2.fill")
                }
            
            FlipView(carManager: carManager)
                .tabItem {
                    Label("Flip", systemImage: "arrow.2.squarepath")
                }
            
            HistoryView(carManager: carManager)
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
        }
    }
} 