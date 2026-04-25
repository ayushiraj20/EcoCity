
<h1 align="center">🌿 EcoCity</h1>

<p align="center">
  <strong>Transform a polluted city into a green utopia — one eco-mission at a time.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white" alt="Swift 6.0"/>
  <img src="https://img.shields.io/badge/Platform-iPad%20%7C%20iPhone-blue?logo=apple" alt="Platform"/>
  <img src="https://img.shields.io/badge/Category-Education-green" alt="Category"/>
  <img src="https://img.shields.io/badge/3D%20Engine-SceneKit-orange" alt="SceneKit"/>
  <img src="https://img.shields.io/badge/UI-SwiftUI-purple?logo=swift" alt="SwiftUI"/>
</p>

---

## 📖 About

**EcoCity** is an interactive educational game built as a Swift Playground for iPad & iPhone. Players take on environmental challenges — planting forests, cleaning rivers, installing renewable energy, and more — to heal a polluted city and watch it transform in real-time 3D.

Every action impacts real-world metrics like **Air Quality Index (AQI)** and **life expectancy**, teaching players the tangible effects of sustainability through gameplay.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🎮 **8 Eco-Missions** | Plant trees, clean rivers, install solar & wind power, build hydroelectric dams, deploy EVs, add industrial filters, and set up water treatment |
| 🏙️ **Live 3D City** | Interactive SceneKit city that visually evolves as you complete levels — smog clears, greenery appears, clean energy infrastructure rises |
| 📊 **Real-Time Metrics** | Track AQI, life expectancy, eco score, happiness, and green actions as your city transforms |
| 🎓 **Educational Content** | Before and after each level, learn real-world environmental statistics and health impacts |
| 🔊 **Immersive Audio** | Ambient bird songs, water sounds, and wind that dynamically play as your city gets cleaner |
| 📱 **Polished Onboarding** | Beautiful onboarding flow with cinematic 3D city backdrop and smooth animations |
| 🏆 **Progress Dashboard** | Rich dashboard with mini 3D city preview, featured tasks, city status, and rotating eco-facts |

---

## 🎮 Levels

| # | Mission | Goal |
|---|---|---|
| 1 | 🌳 **Plant Trees** | Tap to plant 5 trees and reduce CO2 levels |
| 2 | 🏞️ **Clean River** | Remove 7 waste items from the polluted river |
| 3 | ☀️ **Solar Power** | Install 3 solar panel systems on rooftops |
| 4 | 💨 **Wind Energy** | Build 3 wind turbines |
| 5 | 🌊 **Hydro Power** | Construct a hydroelectric dam |
| 6 | 🚗 **Electric Vehicles** | Replace 5 gas cars with EVs |
| 7 | 🏭 **Smoke Filters** | Install 4 industrial emission filters |
| 8 | 🧪 **Water Treatment** | Set up 2 water treatment systems |

---

## 🏗️ Architecture

```
EcoCity.swiftpm/
├── GreenCityApp.swift          # App entry point & environment setup
├── Package.swift               # Swift Package config (iOS 26+)
│
├── Models/
│   ├── GameStateManager.swift  # Observable game state: AQI, life expectancy, progress
│   ├── Level.swift             # Level definitions with educational content
│   └── NavigationPathKey.swift # Navigation state management
│
├── GameEngine/
│   ├── GameSceneView.swift     # Interactive SceneKit game view with tap gestures
│   ├── SceneManager.swift      # 3D scene builder — procedural city generation
│   └── SoundManager.swift      # Ambient & SFX audio management
│
├── Views/
│   ├── ContentView.swift       # Tab-based root view (Dashboard + City)
│   ├── DashboardView.swift     # Home dashboard with metrics & mini 3D city
│   ├── CityView.swift          # Full-screen explorable 3D city
│   ├── LevelSelectionView.swift# Grid-based level picker with progress
│   ├── GameOverlayView.swift   # HUD overlays during gameplay
│   ├── OnboardingView.swift    # Cinematic onboarding experience
│   └── UIComponents.swift      # Shared UI helpers
│
└── 🔊 Audio Assets
    ├── birds.wav               # Bird ambiance (clean city)
    ├── water.wav               # Water sounds (pristine environment)
    ├── wind.wav                # Wind ambiance
    ├── level_complete.wav      # Level completion SFX
    └── task_success.wav        # Task completion SFX
```

---

## 🛠️ Tech Stack

- **Language:** Swift 6.0 with strict concurrency (`@MainActor`, `@Observable`)
- **UI Framework:** SwiftUI
- **3D Engine:** SceneKit — procedurally generated city with buildings, vehicles, nature, water, and atmospheric effects
- **Audio:** AVFoundation — layered ambient soundscapes that respond to game state
- **State Management:** `@Observable` macro with SwiftUI `@Environment` injection
- **Persistence:** `@AppStorage` for onboarding state

---

## 🚀 Getting Started

### Prerequisites
- **Xcode 16+** or **Swift Playgrounds 4+**
- **iOS 26.0+** / **iPadOS 26.0+**

### Run the App
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/EcoCity.git
   ```
2. Open `EcoCity.swiftpm` in **Xcode** or **Swift Playgrounds on iPad**
3. Build & run on a simulator or device (`⌘ + R`)

> **Tip:** The app is optimized for **landscape orientation** on both iPhone and iPad.

---

## 🎯 How It Works

1. **Start the app** — Complete the onboarding to learn the mission
2. **Dashboard** — See your city's health metrics and pick a featured task
3. **Complete levels** — Tap interactive elements in the 3D scene to take eco-actions
4. **Watch the impact** — AQI drops, life expectancy rises, and your 3D city transforms
5. **Explore your city** — Visit the City tab to orbit and explore your creation
6. **Achieve Green City** — Complete all 8 levels to reach utopia! 🌿

---

## 📸 App Tabs

| Dashboard | City View |
|---|---|
| Rich metrics dashboard with mini 3D city preview, eco score, featured tasks, and rotating facts | Full-screen interactive 3D city that evolves with your progress |

---



<p align="center">
  Made with 💚 for a greener planet
</p>
