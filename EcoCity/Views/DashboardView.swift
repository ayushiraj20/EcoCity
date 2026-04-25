import SwiftUI
import SceneKit
import Combine

struct DashboardView: View {
    @Environment(GameStateManager.self) private var gameState
    @Binding var selectedTab: Int
    
    @State private var citySceneManager = SceneManager()
    @State private var lastBuiltLevels: Set<Int>? = nil
    @State private var currentFactIndex = 0
    @State private var showAllTasks = false
    
    private let cityFacts = [
        ("🌳", "Urban trees cool cities by up to 10°F through shade and evapotranspiration."),
        ("☀️", "Solar energy is now the cheapest source of electricity in history."),
        ("💨", "A single wind turbine can power over 1,500 homes with zero emissions."),
        ("🚗", "Cities with high EV adoption see 20-30% reduction in childhood asthma."),
        ("🌊", "Hydropower provides 16% of the world's electricity renewably."),
        ("🏭", "Industrial scrubbers capture up to 99% ofr toxic particulates."),
        ("🧪", "Modern water treatment removes 99.9% of harmful pathogens."),
        ("🌍", "Transitioning to clean energy could prevent 7 million deaths annually.")
    ]
    let factTimer = Timer.publish(every: 6, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.93, green: 0.97, blue: 0.93),
                    Color(red: 0.85, green: 0.95, blue: 0.88),
                    Color(red: 0.90, green: 0.96, blue: 0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    headerSection
                    GeometryReader { geo in
                        HStack(alignment: .top, spacing: 16) {
                            miniCityCard
                                .frame(width: (geo.size.width - 16) * 0.58)
                            
                            VStack(spacing: 10) {
                                cityStatusCard
                                
                                HStack(spacing: 10) {
                                    StatCard(
                                        icon: "leaf.fill",
                                        value: "\(Int(ecoScore * 100))",
                                        label: "ECO SCORE",
                                        color: .green,
                                        trend: nil
                                    )
                                    StatCard(
                                        icon: "heart.fill",
                                        value: "\(Int(gameState.lifeExpectancy))",
                                        label: "LIFE YRS",
                                        color: .pink,
                                        trend: nil
                                    )
                                }
                                
                                HStack(spacing: 10) {
                                    StatCard(
                                        icon: "arrowtriangle.right.circle.fill",
                                        value: "\(gameState.greenActivitiesCompleted)",
                                        label: "ACTIONS",
                                        color: .yellow,
                                        trend: nil
                                    )
                                    StatCard(
                                        icon: "checklist",
                                        value: "\(gameState.completedLevels.count)/8",
                                        label: "TASKS",
                                        color: .mint,
                                        trend: nil
                                    )
                                }
                            }
                            .frame(width: (geo.size.width - 16) * 0.42, height: 400)
                        }
                    }
                    .frame(height: 400)
                    featuredTasksSection
                    cityFactCard
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .onAppear {
            rebuildCityIfNeeded()
        }
        .onChange(of: gameState.completedLevels) { _, _ in
            rebuildCityIfNeeded()
        }
        .onReceive(factTimer) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentFactIndex = (currentFactIndex + 1) % cityFacts.count
            }
        }
    }
    
    private func rebuildCityIfNeeded() {
        let current = gameState.completedLevels
        guard current != lastBuiltLevels else { return }
        lastBuiltLevels = current
        citySceneManager.setupCityScene(completedLevels: current)
    }

    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("EcoCity")
                    .font(.largeTitle.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.1, green: 0.5, blue: 0.2), Color(red: 0.2, green: 0.7, blue: 0.4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text(greeting)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.2), lineWidth: 4)
                        .frame(width: 52, height: 52)
                    Circle()
                        .trim(from: 0, to: ecoScore)
                        .stroke(
                            LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(ecoScore * 100))")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.1, green: 0.5, blue: 0.2))
                }
                Text("ECO")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning! Build a sustainable future 🌱" }
        if hour < 17 { return "Good afternoon! Keep going green 🌿" }
        return "Good evening! Your city awaits 🌙"
    }
    
    private var ecoScore: Double {
        let levelScore = Double(gameState.completedLevels.count) / 9.0
        let aqiScore = max(0, (300.0 - gameState.globalAQI) / 300.0)
        return min(1.0, (levelScore * 0.6 + aqiScore * 0.4))
    }
    
    
    private var miniCityCard: some View {
        ZStack(alignment: .bottomLeading) {
            MiniCitySceneContainer(sceneManager: citySceneManager)
                .frame(height: 400)
                .clipShape(RoundedRectangle(cornerRadius: 24))
            
            LinearGradient(
                colors: [.clear, .black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 24,
                    bottomTrailingRadius: 24,
                    topTrailingRadius: 0
                )
            )
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("EcoCity")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                    Text("\(gameState.completedLevels.count) of 8 green upgrades active")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Button {
                    withAnimation { selectedTab = 1 }
                } label: {
                    HStack(spacing: 4) {
                        Text("Explore")
                            .font(.caption.bold())
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.white.opacity(0.25)))
                }
            }
            .padding(16)
        }
        .shadow(color: .black.opacity(0.15), radius: 15, y: 8)
    }
    
    
    private var cityStatusCard: some View {
        HStack(spacing: 12) {
            Text(happinessEmoji)
                .font(.system(size: 36))
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("City Status")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(red: 0.15, green: 0.4, blue: 0.2))
                    
                    Text(happinessLabel)
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(getAQIColor(gameState.globalAQI)))
                }
                
                Text(cityStatusText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
        .overlay(alignment: .leading) {
            UnevenRoundedRectangle(
                topLeadingRadius: 18,
                bottomLeadingRadius: 18,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            )
            .fill(getAQIColor(gameState.globalAQI))
            .frame(width: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    private var cityStatusText: String {
        switch gameState.globalAQI {
        case 300...: return "Critical pollution levels. The air is toxic and visibility is near zero. Immediate action required!"
        case 200..<300: return "Hazardous smog blankets the city. Severe health warnings are in effect for all citizens."
        case 100..<200: return "Unhealthy air quality. Industrial emissions are noticeably affecting daily life."
        case 50..<100: return "Air quality is improving! Renewable energy initiatives are starting to clear the smog."
        default: return "Pristine air quality! The city is thriving, green, and completely sustainable. 🌿"
        }
    }
    
    private var happinessEmoji: String {
        switch gameState.happinessScore {
        case 1: return "😷"
        case 2: return "☹️"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "🤩"
        default: return "😐"
        }
    }
    
    private var happinessLabel: String {
        switch gameState.happinessScore {
        case 1: return "Critical"
        case 2: return "Unhealthy"
        case 3: return "Moderate"
        case 4: return "Healthy"
        case 5: return "Thriving"
        default: return "Unknown"
        }
    }
    
    
    private var featuredTasksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("🌍")
                    .font(.title3)
                Text("Featured Tasks")
                    .font(.title3.bold())
                    .foregroundStyle(Color(red: 0.15, green: 0.5, blue: 0.2))
                Spacer()
                Button {
                    showAllTasks = true
                } label: {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.subheadline.bold())
                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .foregroundStyle(Color(red: 0.15, green: 0.5, blue: 0.2))
                }
            }
            
            let tasks = featuredTasks
            ForEach(Array(tasks.enumerated()), id: \.element.id) { index, level in
                FeaturedTaskRow(
                    level: level,
                    isCompleted: gameState.completedLevels.contains(level.id),
                    isUnlocked: level.id <= gameState.unlockedLevels,
                    isLast: index == tasks.count - 1,
                    selectedTab: $selectedTab
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        )
        .navigationDestination(isPresented: $showAllTasks) {
            LevelSelectionView(selectedTab: $selectedTab)
        }
    }
    
    private var featuredTasks: [Level] {
        let uncompleted = Level.allLevels.filter { !gameState.completedLevels.contains($0.id) }
        if uncompleted.isEmpty {
            return Array(Level.allLevels.prefix(3))
        }
        return Array(uncompleted.prefix(3))
    }
    
    
    private var cityFactCard: some View {
        HStack(spacing: 14) {
            Text(cityFacts[currentFactIndex].0)
                .font(.system(size: 32))
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Did You Know?")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                Text(cityFacts[currentFactIndex].1)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.08), Color.mint.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .green.opacity(0.08), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.green.opacity(0.15), lineWidth: 1)
        )
        .id(currentFactIndex)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: .leading))
        ))
    }
}


struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    var trend: String?
    
    var body: some View {
        VStack(spacing: 8) { // Slightly increased spacing to accommodate larger icon
            HStack(spacing: 6) { // Slightly increased spacing between icon and text
                if !icon.isEmpty {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold)) // Increased from 10 to 16
                        .foregroundStyle(color)
                }
                Text(label)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
            }
            
            HStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.15, green: 0.4, blue: 0.2))
                    .contentTransition(.numericText())
                
                if let trend {
                    Text(trend)
                        .font(.caption2.bold())
                        .foregroundStyle(trend == "↑" ? .green : .orange)
                }
            }
        }
        .padding(.vertical, 14)
        .frame(minWidth: 0, maxWidth: .infinity)
        .frame(minHeight: 0, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: color.opacity(0.1), radius: 6, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}

struct FeaturedTaskRow: View {
    let level: Level
    let isCompleted: Bool
    let isUnlocked: Bool
    var isLast: Bool = false
    @Binding var selectedTab: Int
    
    @State private var navigateToGame = false
    
    private var accentColor: Color {
        switch level.id {
        case 1: return .green
        case 2: return .blue
        case 3: return .yellow
        case 4: return .cyan
        case 5: return .blue
        case 6: return .green
        case 7: return .indigo
        case 8: return .teal
        case 9: return .mint
        default: return .green
        }
    }
    
    var body: some View {
        Button {
            if isUnlocked { navigateToGame = true }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: level.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(isUnlocked ? accentColor : .gray)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(level.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(isUnlocked ? Color(red: 0.15, green: 0.4, blue: 0.2) : .gray)
                    Text(level.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                } else if isUnlocked {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                        .foregroundStyle(accentColor)
                } else {
                    Image(systemName: "lock.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.gray.opacity(0.4))
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
        .navigationDestination(isPresented: $navigateToGame) {
            GameSceneView(level: level, selectedTab: $selectedTab)
                .navigationBarBackButtonHidden(true)
        }
        
        if !isLast {
            Divider()
                .padding(.leading, 58)
        }
    }
}

struct MiniCitySceneContainer: UIViewRepresentable {
    let sceneManager: SceneManager
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = sceneManager.scene
        scnView.pointOfView = sceneManager.cameraNode
        scnView.allowsCameraControl = false // Non-interactive preview
        scnView.autoenablesDefaultLighting = false
        scnView.backgroundColor = UIColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 1.0)
        scnView.antialiasingMode = .multisampling4X
        scnView.isUserInteractionEnabled = false
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
}
