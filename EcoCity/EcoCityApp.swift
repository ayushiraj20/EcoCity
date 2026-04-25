//
//  EcoCityApp.swift
//  EcoCity
//
//  Created by Ayushi on 25/04/26.
//

import SwiftUI

@main
struct EcoCityApp: App {
    @State private var gameState = GameStateManager()
    @State private var soundManager = SoundManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environment(gameState)
                    .environment(soundManager)
                    .onAppear {
                        gameState.soundManager = soundManager
                    }
                    .preferredColorScheme(.light)
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .preferredColorScheme(.dark)
            }
        }
    }
}
