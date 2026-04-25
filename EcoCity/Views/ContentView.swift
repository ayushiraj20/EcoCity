import SwiftUI

struct ContentView: View {
    @Environment(GameStateManager.self) private var gameState
    @State private var selectedTab = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2.fill")
            }
            .tag(0)
            CityView(selectedTab: $selectedTab)
                .tabItem {
                    Label("City", systemImage: "building.2.fill")
                }
                .tag(1)
        }
        .tint(.green)
        .fullScreenCover(isPresented: .init(
            get: { !hasCompletedOnboarding },
            set: { _ in }
        )) {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        }
    }
}

