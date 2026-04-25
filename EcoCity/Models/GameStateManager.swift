import SwiftUI
import Observation

@MainActor
@Observable
class GameStateManager {
    var globalAQI: Double = 300.0 // Starts very bad
    var lifeExpectancy: Double = 60.0 // Starts low
    var happinessScore: Int = 1 //  Extremely Unhealthy, Extremely Healthy
    
    var soundManager: SoundManager?
    
    var pollutionEliminated: Double = 0.0
    var greenActivitiesCompleted: Int = 0
    
    var unlockedLevels: Int = 1
    var currentLevel: Int? = nil // nil means on main menu or level select
    var isLevelActionComplete: Bool = false
    var completedLevels: Set<Int> = []
    
    var levelItemsTotal: Int = 0
    var levelItemsDone: Int = 0
    
    var levelProgressText: String {
        guard levelItemsTotal > 0 else { return "" }
        return "\(levelItemsDone)/\(levelItemsTotal)"
    }
    
    var levelsCompleted: Int {
        completedLevels.count
    }
    
    func unlockNextLevel() {
        if unlockedLevels < 8 {
            unlockedLevels += 1
        }
    }
    
    func markLevelComplete(_ levelId: Int) {
        completedLevels.insert(levelId)
        isLevelActionComplete = true
        unlockNextLevel()
        soundManager?.playLevelComplete()
    }
    
    func completeLevelAction(aqiReduction: Double, lifeExpectancyIncrease: Double) {
        globalAQI -= aqiReduction
        if globalAQI < 0 { globalAQI = 0 }
        
        lifeExpectancy += lifeExpectancyIncrease
        if lifeExpectancy > 100 { lifeExpectancy = 100 }
        
        greenActivitiesCompleted += 1
        pollutionEliminated += aqiReduction
        levelItemsDone += 1
        
        updateHappiness()
    }
    
    private func updateHappiness() {
        if globalAQI > 250 {
            happinessScore = 1 // Extremely Unhealthy
        } else if globalAQI > 150 {
            happinessScore = 2 // Unhealthy
        } else if globalAQI > 80 {
            happinessScore = 3 // Bearable
        } else if globalAQI > 30 {
            happinessScore = 4 // Healthy
        } else {
            happinessScore = 5 // Extremely Healthy
        }
    }
    
    var treesPlanted: Int = 0
    var garbageRemoved: Int = 0
}
