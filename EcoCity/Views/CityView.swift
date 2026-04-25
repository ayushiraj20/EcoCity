import SwiftUI
import SceneKit

struct CityView: View {
    @Environment(GameStateManager.self) private var gameState
    @Environment(SoundManager.self) private var soundManager
    @Binding var selectedTab: Int
    @State private var citySceneManager = SceneManager()
    @State private var lastBuiltLevels: Set<Int>? = nil
    
    var body: some View {
        ZStack {
            CitySceneContainer(sceneManager: citySceneManager)
                .ignoresSafeArea()
            HStack {
                VStack {
                    cityMetricsOverlay
                        .padding(.leading, 16)
                        .padding(.top, 16)
                    Spacer()
                }
                Spacer()
            }
            
            VStack {
                Spacer()
                completionBadge
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
        .onAppear {
            citySceneManager.gameState = gameState
            rebuildCityIfNeeded()
            startSoundsIfNeeded()
        }
        .onDisappear {
            soundManager.stopAmbient()
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == 1 {
                startSoundsIfNeeded()
            } else {
                soundManager.stopAmbient()
            }
        }
        .onChange(of: gameState.completedLevels) { _, _ in
            rebuildCityIfNeeded()
        }
    }
    
    private func rebuildCityIfNeeded() {
        let current = gameState.completedLevels
        guard current != lastBuiltLevels else { return }
        lastBuiltLevels = current
        citySceneManager.setupCityScene(completedLevels: current)
    }
    
    private func startSoundsIfNeeded() {
        if gameState.globalAQI < 150 {
            soundManager.playCityAmbient()
        } else {
            soundManager.stopAmbient()
        }
    }
    
    
    private var cityMetricsOverlay: some View {
        VStack(spacing: 20) {
            VStack(spacing: 20) {
                metricPill(icon: "wind", label: "AQI", value: "\(Int(gameState.globalAQI))", color: aqiColor)
                metricPill(icon: "heart.fill", label: "Life", value: "\(Int(gameState.lifeExpectancy))yr", color: .pink)
                metricPill(icon: "checkmark.circle.fill", label: "Done", value: "\(gameState.completedLevels.count)/8", color: .green)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
            )
        }
    }
    
    private func metricPill(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 44)
    }
    
    private var completionBadge: some View {
        Group {
            if gameState.completedLevels.count == 0 {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Complete levels to build your green city!")
                        .font(.caption.bold())
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
                )
            } else if gameState.completedLevels.count >= 8 {
                HStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(.green)
                    Text("Green City Achieved!")
                        .font(.caption.bold())
                        .foregroundStyle(.primary)
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(.green)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .green.opacity(0.3), radius: 8, y: 3)
                )
            }
        }
    }
    
    private var aqiColor: Color {
        getAQIColor(gameState.globalAQI)
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
}

struct CitySceneContainer: UIViewRepresentable {
    let sceneManager: SceneManager
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = sceneManager.scene
        scnView.pointOfView = sceneManager.cameraNode
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = false
        scnView.backgroundColor = UIColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 1.0)
        scnView.antialiasingMode = .multisampling4X
        
        scnView.defaultCameraController.maximumVerticalAngle = 85
        scnView.defaultCameraController.minimumVerticalAngle = 10
        scnView.defaultCameraController.maximumHorizontalAngle = 45
        scnView.defaultCameraController.minimumHorizontalAngle = -45
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
}
