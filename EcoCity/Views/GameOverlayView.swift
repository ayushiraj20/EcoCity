import SwiftUI

struct GameOverlayPanel: View {
    enum DisplayMode {
        case full
        case metricsOnly
        case infoOnly   
    }
    
    @Environment(GameStateManager.self) private var gameState
    let level: Level
    var displayMode: DisplayMode = .full
    var onNextLevel: ((Level) -> Void)? = nil
    var onVisitCity: (() -> Void)? = nil
    
    private var nextLevel: Level? {
        Level.allLevels.first(where: { $0.id == level.id + 1 })
    }
    
    var body: some View {
        switch displayMode {
        case .full:
            fullPanel
        case .metricsOnly:
            metricsSection
        case .infoOnly:
            infoSection
        }
    }
    
    private var fullPanel: some View {
        VStack(spacing: 12) {
            metricsContent
            infoContent
        }
    }
    
    private var metricsSection: some View {
        VStack(spacing: 12) {
            metricsContent
        }
    }
    
    private var infoSection: some View {
        infoContent
    }
    
    var objectiveBox: some View {
        HStack(spacing: 10) {
            Image(systemName: "target")
                .font(.title3)
                .foregroundStyle(.orange)
            Text(":")
                .font(.subheadline.bold())
                .foregroundStyle(.gray)
            Text(level.description)
                .font(.callout)
                .foregroundStyle(Color(red: 0.15, green: 0.4, blue: 0.2))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)  // Allows it to fully occupy the 80pt layout height flexibly
        .background(RoundedRectangle(cornerRadius: 12).fill(.white).shadow(color: .black.opacity(0.06), radius: 4, y: 2))
    }
    
    private var metricsContent: some View {
        VStack(spacing: 12) {
            
            VStack(spacing: 10) {
                MetricBar(title: "AQI (Air Quality)", value: gameState.globalAQI, maxValue: 400, invertedMode: true)
                MetricBar(title: "Life Expectancy", value: gameState.lifeExpectancy, maxValue: 100, invertedMode: false)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 12).fill(.white).shadow(color: .black.opacity(0.06), radius: 4, y: 2))
            
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text(happinessEmoji(gameState.happinessScore))
                        .font(.system(size: 36))
                        .shadow(radius: 4)
                        .scaleEffect(gameState.isLevelActionComplete ? 1.15 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: gameState.happinessScore)
                    Text(happinessText(gameState.happinessScore))
                        .font(.caption2.bold())
                        .foregroundStyle(Color(red: 0.15, green: 0.4, blue: 0.2))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(.white).shadow(color: .black.opacity(0.06), radius: 4, y: 2))
                
                if gameState.levelItemsTotal > 0 {
                    VStack(spacing: 4) {
                        Text(gameState.levelProgressText)
                            .font(.title2.bold().monospacedDigit())
                            .foregroundStyle(.green)
                            .contentTransition(.numericText())
                            .animation(.spring, value: gameState.levelItemsDone)
                        Text(progressLabel)
                            .font(.caption2.bold())
                            .foregroundStyle(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.white).shadow(color: .black.opacity(0.06), radius: 4, y: 2))
                }
            }
        }
    }
    
    private var infoContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    if gameState.isLevelActionComplete {
                        HStack(spacing: 10) {
                            Image(systemName: "trophy.fill")
                                .font(.title2)
                                .foregroundStyle(.yellow)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Task Completed!")
                                    .font(.title3.bold())
                                    .foregroundStyle(Color(red: 0.15, green: 0.4, blue: 0.2))
                                Text("All objectives fulfilled")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                            Spacer()
                            
                            Image(systemName: "checkmark.seal.fill")
                                .font(.title2)
                                .foregroundStyle(.green)
                        }
                        .padding(.bottom, 4)
                        
                        Divider()
                            .background(Color.green.opacity(0.3))
                    }
                    
                    HStack {
                        Image(systemName: gameState.isLevelActionComplete ? "lightbulb.fill" : "info.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(gameState.isLevelActionComplete ? .yellow : .blue)
                        Text(gameState.isLevelActionComplete ? "Impact & Benefits" : "Did you know?")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color(red: 0.15, green: 0.4, blue: 0.2))
                    }
                    
                    Text(gameState.isLevelActionComplete ? level.educationalTextAfter : level.educationalTextBefore)
                        .font(.callout)
                        .foregroundStyle(Color(white: 0.3))
                }
                .padding()
            }
            
            if gameState.isLevelActionComplete, let next = nextLevel {
                Button {
                    onNextLevel?(next)
                } label: {
                    HStack {
                        Text("Next: \(next.title)")
                            .font(.headline.bold())
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing))
                    )
                    .foregroundStyle(.black)
                }
                .buttonStyle(SpringyButtonStyle())
                .padding([.horizontal, .bottom])
            }
            
            if gameState.isLevelActionComplete && nextLevel == nil && level.id == 8 {
                Button {
                    onVisitCity?()
                } label: {
                    HStack {
                        Image(systemName: "building.2.fill")
                            .font(.title3)
                        Text("Visit EcoCity")
                            .font(.headline.bold())
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing))
                    )
                    .foregroundStyle(.black)
                }
                .buttonStyle(SpringyButtonStyle())
                .padding([.horizontal, .bottom])
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(gameState.isLevelActionComplete
                        ? Color.green.opacity(0.3)
                        : Color.blue.opacity(0.2), lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.5), value: gameState.isLevelActionComplete)
    }
    
    private var progressLabel: String {
        switch level.id {
        case 1: return "Trees Planted"
        case 2: return "Garbage Removed"
        case 3: return "Panels Installed"
        case 4: return "Windmills Built"
        case 5: return "Dams Built"
        case 6: return "Cars Replaced"
        case 7: return "Filters Added"
        case 8: return "Pipes Treated"
        default: return "Complete"
        }
    }
    
    private func happinessEmoji(_ score: Int) -> String {
        switch score {
        case 1: return "😷"
        case 2: return "☹️"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "🤩"
        default: return "😐"
        }
    }
    
    private func happinessText(_ score: Int) -> String {
        switch score {
        case 1: return "Toxic"
        case 2: return "Unhealthy"
        case 3: return "Bearable"
        case 4: return "Healthy"
        case 5: return "Ideal"
        default: return "Unknown"
        }
    }
}

struct MetricBar: View {
    let title: String
    let value: Double
    let maxValue: Double
    let invertedMode: Bool // If true, higher value is worse (red), lower is better (green)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption.bold())
                Spacer()
                Text("\(Int(value))")
                    .font(.caption.monospacedDigit().bold())
                    .contentTransition(.numericText())
            }
            .foregroundStyle(Color(red: 0.15, green: 0.4, blue: 0.2))
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.08))
                    
                    let percentage = min(max(value / maxValue, 0), 1)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(barGradient(for: percentage))
                        .frame(width: geo.size.width * CGFloat(percentage))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: value)
                }
            }
            .frame(height: 10)
        }
    }
    
    private func barGradient(for percentage: Double) -> LinearGradient {
        if invertedMode {
            let color = Color(
                hue: (1.0 - percentage) * 0.33,
                saturation: 0.85,
                brightness: 0.9
            )
            return LinearGradient(colors: [color.opacity(0.8), color], startPoint: .leading, endPoint: .trailing)
        } else {
            let color = Color(
                hue: percentage * 0.33,
                saturation: 0.85,
                brightness: 0.9
            )
            return LinearGradient(colors: [color.opacity(0.8), color], startPoint: .leading, endPoint: .trailing)
        }
    }
}
