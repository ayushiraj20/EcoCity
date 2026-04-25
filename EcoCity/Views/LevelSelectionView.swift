import SwiftUI

struct LevelSelectionView: View {
    @Environment(GameStateManager.self) private var gameState
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Int
    
    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.white, Color(red: 0.85, green: 0.95, blue: 0.85)],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
            
            VStack(spacing: 0) {
                progressDashboard
                    .padding()
                    .background(Color.white.opacity(0.9).ignoresSafeArea(edges: .top))
                    .shadow(color: .black.opacity(0.05), radius: 10)
                
                GeometryReader { geo in
                    let availableHeight = geo.size.height
                    let rows = 3 
                    let totalSpacing: CGFloat = CGFloat(rows - 1) * 20 + 48
                    let cardHeight = max(120, (availableHeight - totalSpacing) / CGFloat(rows))
                    
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(Level.allLevels) { level in
                                LevelCardView(
                                    level: level,
                                    isUnlocked: level.id <= gameState.unlockedLevels,
                                    isCompleted: gameState.completedLevels.contains(level.id),
                                    cardHeight: cardHeight,
                                    selectedTab: $selectedTab
                                )
                            }
                        }
                        .padding(24)
                    }
                }
            }
        }
    }
    
    private var progressDashboard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                DashboardMetric(title: "POLLUTION\nCLEARED", value: "\(Int(gameState.pollutionEliminated)) AQI", icon: "wind", color: getAQIColor(gameState.globalAQI))
                
                Divider().background(.gray).frame(height: 40)
                
                DashboardMetric(title: "GREEN\nACTIONS", value: "\(gameState.greenActivitiesCompleted)", icon: "leaf.fill")
                
                Divider().background(.gray).frame(height: 40)
                
                DashboardMetric(title: "LIFE\nEXPECTANCY", value: "\(Int(gameState.lifeExpectancy)) yrs", icon: "heart.fill", color: .red)
            }
        }
    }
}

struct DashboardMetric: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .green
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(.gray)
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(Color(red: 0.15, green: 0.4, blue: 0.2))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct LevelCardView: View {
    let level: Level
    let isUnlocked: Bool
    let isCompleted: Bool
    var cardHeight: CGFloat = 150
    @Binding var selectedTab: Int
    
    @State private var navigateToGame = false
    
    private var levelAccent: Color {
        switch level.id {
        case 1: return .green       // Plant Trees
        case 2: return .blue        // Clean River
        case 3: return .yellow      // Solar Power
        case 4: return .cyan        // Wind Energy
        case 5: return .blue        // Hydro Power
        case 6: return .green       // Electric Vehicles
        case 7: return Color(white: 0.35)  // Smoke Filters
        case 8: return .teal        // Water Treatment
        default: return .green
        }
    }
    
    private var iconColor: Color { isUnlocked ? levelAccent : .gray }
    private var titleColor: Color { isUnlocked ? Color(red: 0.15, green: 0.4, blue: 0.2) : .gray }
    private var shadowColor: Color { isUnlocked ? levelAccent.opacity(0.2) : .black.opacity(0.05) }
    private var strokeColor: Color {
        if isCompleted { return levelAccent.opacity(0.8) }
        if isUnlocked { return levelAccent.opacity(0.3) }
        return Color.gray.opacity(0.2)
    }
    private var strokeWidth: CGFloat { isCompleted ? 2.5 : 1.5 }
    
    var body: some View {
        Button {
            navigateToGame = true
        } label: {
            cardLabel
        }
        .disabled(!isUnlocked)
        .buttonStyle(SpringyButtonStyle())
        .navigationDestination(isPresented: $navigateToGame) {
            GameSceneView(level: level, selectedTab: $selectedTab)
                .navigationBarBackButtonHidden(true)
        }
    }
    
    private var cardLabel: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 10) {
                Spacer()
                
                Image(systemName: level.iconName)
                    .font(.system(size: 48))
                    .foregroundStyle(iconColor)
                
                Text(level.title)
                    .font(.headline.bold())
                    .foregroundStyle(titleColor)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: cardHeight)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: shadowColor, radius: 10, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(strokeColor, lineWidth: strokeWidth)
            )
            
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(levelAccent)
                    .background(Circle().fill(Color.white).padding(-3))
                    .offset(x: 8, y: -8)
            }
        }
    }
}
