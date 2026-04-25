import SwiftUI
import SceneKit

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var isAnimatingOrb = false
    @State private var floatingOffset: CGFloat = 0.0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            titlePrimary: "Heal the City",
            description: "Take the lead in building a carbon-neutral metropolis.",
            tint: .green,
            icon1: "building.2.fill",
            icon2: "",
            gradient: [.green, .mint]
        ),
        OnboardingPage(
            titlePrimary: "Track the Living Data",
            description: "Watch the AQI drop and life expectancy rise.",
            tint: .green,
            icon1: "waveform.path.ecg",
            icon2: "",
            gradient: [.green, .mint]
        ),
        OnboardingPage(
            titlePrimary: "Achieve Utopia",
            description: "Complete all missions and witness nature's majestic return to the heart of the city.",
            tint: .green,
            icon1: "globe.americas.fill",
            icon2: "",
            gradient: [.green, .mint]
        )
    ]
    @State private var introSceneManager = SceneManager()

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            CinematicBackgroundContainer(sceneManager: introSceneManager)
                .ignoresSafeArea()
                .scaleEffect(1.05)
                .opacity(0.85)
                .blur(radius: 8)

            Color.black.opacity(0.15)
                .ignoresSafeArea()

            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingCardView(
                        page: pages[index],
                        pageIndex: index,
                        totalPages: pages.count,
                        currentPage: $currentPage,
                        floatingOffset: floatingOffset,
                        onComplete: {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                hasCompletedOnboarding = true
                            }
                        }
                    )
                    .tag(index)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 40)
                    .frame(maxWidth: 420, maxHeight: 600)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.4), value: currentPage)
        }
        .onAppear {
            isAnimatingOrb = true
            introSceneManager.setupCityScene(completedLevels: [1, 2, 3, 4, 5, 6, 7, 8])
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                floatingOffset = -10
            }
        }
    }
}

private struct OnboardingCardView: View {
    let page: OnboardingPage
    let pageIndex: Int
    let totalPages: Int
    @Binding var currentPage: Int
    let floatingOffset: CGFloat
    let onComplete: () -> Void
    
    var isCurrent: Bool {
        currentPage == pageIndex
    }

    var body: some View {
        VStack(spacing: 24) {
            
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.08), radius: 25, y: 15)
                    .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1.5))

                ZStack {
                    Image(systemName: page.icon1)
                        .font(.system(size: 65))
                        .foregroundStyle(Color.black.opacity(0.1))
                        .offset(x: 0, y: 5)

                    Image(systemName: page.icon1)
                        .font(.system(size: 65))
                        .foregroundStyle(
                            LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    
                    if !page.icon2.isEmpty {
                        Image(systemName: page.icon2)
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .background(
                                Circle()
                                    .fill(LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 44, height: 44)
                                    .shadow(color: page.tint.opacity(0.5), radius: 10, y: 5)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            )
                            .offset(x: 32, y: 32)
                    }
                }
            }
            .offset(y: floatingOffset)
            .padding(.top, 40)
            
            HStack(spacing: 8) {
                Text(page.titlePrimary)
            }
            .foregroundStyle(
                LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .font(.system(size: 34, weight: .heavy, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            
            Text(page.description)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)
            
            Spacer(minLength: 16)
            
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? page.tint : Color.white.opacity(0.3))
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                }
            }
            .padding(.bottom, 8)
            
            Button(action: {
                if currentPage < totalPages - 1 {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        currentPage += 1
                    }
                } else {
                    onComplete()
                }
            }) {
                Text(currentPage == totalPages - 1 ? "Start Building" : "Continue")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .shadow(color: page.tint.opacity(0.4), radius: 10, y: 5)
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.3), lineWidth: 1))
                    )
            }
            .padding(.horizontal, 32)
            
            Button(action: onComplete) {
                Text("Skip")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .padding(.vertical, 8)
            }
            .opacity(currentPage == totalPages - 1 ? 0 : 1)
            .padding(.bottom, 24)
        }
        .background(
            RoundedRectangle(cornerRadius: 40)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 40)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 30, y: 15)
        )
        .environment(\.colorScheme, .dark)
        .scaleEffect(isCurrent ? 1.0 : 0.88)
        .opacity(isCurrent ? 1.0 : 0.4)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isCurrent)
    }
}

private struct OnboardingPage {
    let titlePrimary: String
    let description: String
    let tint: Color
    let icon1: String
    let icon2: String
    let gradient: [Color]
}

private struct CinematicBackgroundContainer: UIViewRepresentable {
    let sceneManager: SceneManager
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = sceneManager.scene
        scnView.pointOfView = sceneManager.cameraNode
        scnView.allowsCameraControl = false // Static cinematic view
        scnView.autoenablesDefaultLighting = false
        scnView.backgroundColor = UIColor(red: 0.45, green: 0.72, blue: 0.92, alpha: 1.0)
        scnView.antialiasingMode = .multisampling4X
        scnView.isUserInteractionEnabled = false // Background only
       
        let pivot = SCNNode()
        pivot.position = SCNVector3(10, 0, 5) // City geometric center
        sceneManager.scene.rootNode.addChildNode(pivot)
        
        sceneManager.cameraNode.removeFromParentNode()
        pivot.addChildNode(sceneManager.cameraNode)
        
        sceneManager.cameraNode.position = SCNVector3(0, 45, 50)
        sceneManager.cameraNode.look(at: SCNVector3(0, 0, 0))
        
        let orbit = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 100))
        pivot.runAction(orbit)
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
}

#Preview("Onboarding") {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
