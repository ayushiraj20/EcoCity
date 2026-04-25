import SwiftUI
import SceneKit

struct GameSceneView: View {
    let level: Level
    @Binding var selectedTab: Int
    @Environment(GameStateManager.self) private var gameState
    @Environment(SoundManager.self) private var soundManager
    @State private var sceneManager = SceneManager()
    @State private var currentLevel: Level? = nil
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscapeMode = geometry.size.width > geometry.size.height
            
            ZStack {
                LinearGradient(
                    colors: [.white, Color(red: 0.85, green: 0.95, blue: 0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.bold())
                                .padding(10)
                                .background(Circle().fill(.white).shadow(color: .black.opacity(0.08), radius: 4, y: 2))
                                .foregroundStyle(Color(red: 0.15, green: 0.4, blue: 0.2))
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Image(systemName: activeLevel.iconName)
                                .font(.title2)
                                .foregroundStyle(levelAccentColor(for: activeLevel.id))
                            Text(activeLevel.title)
                                .font(.title.bold())
                                .foregroundStyle(Color(red: 0.15, green: 0.4, blue: 0.2))
                        }
                        
                        Spacer()
                        Color.clear
                            .frame(width: 40, height: 40)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    

                if isLandscapeMode {
                    HStack(alignment: .top, spacing: 0) {
                        VStack(spacing: 6) {
                            SceneViewContainer(sceneManager: sceneManager, level: activeLevel)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal)
                            HStack(alignment: .center, spacing: 14) {
                                ActionButtonsView(level: activeLevel, sceneManager: sceneManager)
                                    .fixedSize(horizontal: true, vertical: false)
                                
                                if activeLevel.id <= 8 {
                                    GameOverlayPanel(level: activeLevel).objectiveBox

                                        .frame(maxHeight: 80)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                        .frame(width: geometry.size.width * 0.65)
                        GameOverlayPanel(level: activeLevel, onNextLevel: { next in
                            switchToLevel(next)
                        }, onVisitCity: {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                selectedTab = 1
                            }
                        })
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding([.trailing, .bottom])
                            .padding(.top, 4)
                    }
                } else {
                    VStack(spacing: 8) {
                        GameOverlayPanel(level: activeLevel, displayMode: .metricsOnly)
                            .padding(.horizontal)
                        VStack(spacing: 0) {
                            SceneViewContainer(sceneManager: sceneManager, level: activeLevel)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal)
                            
                            ActionButtonsView(level: activeLevel, sceneManager: sceneManager)
                                .padding(.horizontal)
                        }
                        .frame(maxHeight: geometry.size.height * 0.45)
                        
                        GameOverlayPanel(level: activeLevel, displayMode: .infoOnly, onNextLevel: { next in
                            switchToLevel(next)
                        }, onVisitCity: {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                selectedTab = 1
                            }
                        })
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }
                }
                }
            } 
        }
        .onAppear {
            soundManager.stopAmbient()
            currentLevel = level
            sceneManager.gameState = gameState
            sceneManager.setupForLevel(level)
            updateSkyFog()
        }
        .onDisappear {
        }
        .navigationBarBackButtonHidden(true)
    }
    private var activeLevel: Level {
        currentLevel ?? level
    }
    private func switchToLevel(_ next: Level) {
        currentLevel = next
        sceneManager.setupForLevel(next)
        updateSkyFog()
    }
    
    private func updateSkyFog() {
        let fogAlpha = max(0.0, gameState.globalAQI / 400.0)
        if fogAlpha > 0.1 {
            sceneManager.scene.fogColor = UIColor(white: 0.5, alpha: CGFloat(fogAlpha))
        } else {
            sceneManager.scene.background.contents = UIColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 1.0)
        }
    }
    private func levelAccentColor(for levelId: Int) -> Color {
        switch levelId {
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
}
struct ActionButtonsView: View {
    let level: Level
    let sceneManager: SceneManager
    @Environment(GameStateManager.self) private var gameState
    
    var body: some View {
        if level.id == 9 {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                Text("🎉 City Complete! Enjoy your green utopia.")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(red: 0.15, green: 0.4, blue: 0.2))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [.green.opacity(0.15), .mint.opacity(0.1)], startPoint: .leading, endPoint: .trailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.4), lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.bottom, 8)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    let remaining = gameState.levelItemsTotal - gameState.levelItemsDone
                    let isComplete = gameState.isLevelActionComplete
                    
                    if level.id == 1 {
                        ActionButton(title: "Plant Tree", icon: "tree.fill", color: .green, badge: remaining, disabled: isComplete) {
                            sceneManager.performAction(actionType: .plantTree)
                        }
                    } else if level.id == 2 {
                        ActionButton(title: "Clean Garbage", icon: "trash.slash.fill", color: .blue, badge: remaining, disabled: isComplete) {
                            sceneManager.performAction(actionType: .cleanGarbage)
                        }
                    } else if level.id == 3 {
                        ActionButton(title: "Add Solar", icon: "sun.max.fill", color: .yellow, badge: remaining, disabled: isComplete) {
                            sceneManager.performAction(actionType: .placeSolar)
                        }
                    } else if level.id == 4 {
                        ActionButton(title: "Add Windmill", icon: "wind", color: .cyan, badge: remaining, disabled: isComplete) {
                            sceneManager.performAction(actionType: .placeWindmill)
                        }
                    } else if level.id == 5 {
                        ActionButton(title: "Build Dam", icon: "drop.fill", color: .cyan, badge: remaining, disabled: isComplete) {
                            sceneManager.performAction(actionType: .placeDam)
                        }
                    } else if level.id == 6 {
                        ActionButton(title: "Deploy EV", icon: "bolt.car.fill", color: .green, badge: remaining, disabled: isComplete) {
                            sceneManager.performAction(actionType: .deployEV)
                        }
                    } else if level.id == 7 {
                        ActionButton(title: "Install Filter", icon: "smoke.fill", color: .blue, badge: remaining, disabled: isComplete) {
                            sceneManager.performAction(actionType: .installFilter)
                        }
                    } else if level.id == 8 {
                        ActionButton(title: "Treat Water", icon: "flask.fill", color: .teal, badge: remaining, disabled: isComplete) {
                            sceneManager.performAction(actionType: .treatWater)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 80)
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var badge: Int = 0
    var disabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 4) {
                    Image(systemName: disabled ? "checkmark.circle.fill" : icon)
                        .font(.title2)
                    Text(disabled ? "Done" : title)
                        .font(.caption.bold())
                }
                .frame(width: 100, height: 60)
                .background(RoundedRectangle(cornerRadius: 12).fill(.white).shadow(color: disabled ? .black.opacity(0.05) : color.opacity(0.25), radius: 4, y: 2))
                .foregroundStyle(disabled ? .gray : color)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(disabled ? Color.gray.opacity(0.2) : color.opacity(0.4), lineWidth: 1.5)
                )
                
                if badge > 0 && !disabled {
                    Text("\(badge)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(color))
                        .offset(x: 6, y: -6)
                }
            }
            .padding(8)
        }
        .disabled(disabled)
        .buttonStyle(SpringyButtonStyle())
    }
}

struct SceneViewContainer: UIViewRepresentable {
    let sceneManager: SceneManager
    let level: Level
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = sceneManager.scene
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = false
        scnView.backgroundColor = UIColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 1.0)
        scnView.antialiasingMode = .multisampling4X
        scnView.defaultCameraController.maximumVerticalAngle = 80
        scnView.defaultCameraController.minimumVerticalAngle = 5
        scnView.defaultCameraController.maximumHorizontalAngle = 45
        scnView.defaultCameraController.minimumHorizontalAngle = -45
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        if context.coordinator.lastLevelId != level.id {
            context.coordinator.lastLevelId = level.id
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 1.0
            
            uiView.pointOfView = sceneManager.cameraNode
            uiView.defaultCameraController.target = sceneManager.cameraTarget
            
            SCNTransaction.commit()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(sceneManager: sceneManager)
    }
    
    class Coordinator: NSObject {
        let sceneManager: SceneManager
        var lastLevelId: Int = -1
        
        init(sceneManager: SceneManager) {
            self.sceneManager = sceneManager
        }
        
        @MainActor @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            let location = gesture.location(in: scnView)
            sceneManager.handleTap(at: location, in: scnView)
        }
    }
}
