//
//  GameDataManager.swift
//  DF727
//
//  Created by IGOR on 01/11/2025.
//

import Foundation
import Combine

class GameDataManager: ObservableObject {
    static let shared = GameDataManager()
    
    @Published var totalEnergyPoints: Int = 0
    @Published var pulseTapBestScore: Int = 0
    @Published var focusShiftBestScore: Int = 0
    @Published var currentStreak: Int = 0
    @Published var gamesPlayed: Int = 0
    @Published var hasCompletedOnboarding: Bool = false
    
    private let defaults = UserDefaults.standard
    
    private init() {
        loadData()
    }
    
    func loadData() {
        totalEnergyPoints = defaults.integer(forKey: "totalEnergyPoints")
        pulseTapBestScore = defaults.integer(forKey: "pulseTapBestScore")
        focusShiftBestScore = defaults.integer(forKey: "focusShiftBestScore")
        currentStreak = defaults.integer(forKey: "currentStreak")
        gamesPlayed = defaults.integer(forKey: "gamesPlayed")
        hasCompletedOnboarding = defaults.bool(forKey: "hasCompletedOnboarding")
    }
    
    func saveData() {
        defaults.set(totalEnergyPoints, forKey: "totalEnergyPoints")
        defaults.set(pulseTapBestScore, forKey: "pulseTapBestScore")
        defaults.set(focusShiftBestScore, forKey: "focusShiftBestScore")
        defaults.set(currentStreak, forKey: "currentStreak")
        defaults.set(gamesPlayed, forKey: "gamesPlayed")
        defaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
    }
    
    func addEnergyPoints(_ points: Int) {
        totalEnergyPoints += points
        saveData()
    }
    
    func updatePulseTapScore(_ score: Int) {
        if score > pulseTapBestScore {
            pulseTapBestScore = score
        }
        gamesPlayed += 1
        saveData()
    }
    
    func updateFocusShiftScore(_ score: Int) {
        if score > focusShiftBestScore {
            focusShiftBestScore = score
        }
        gamesPlayed += 1
        saveData()
    }
    
    func incrementStreak() {
        currentStreak += 1
        saveData()
    }
    
    func resetProgress() {
        totalEnergyPoints = 0
        pulseTapBestScore = 0
        focusShiftBestScore = 0
        currentStreak = 0
        gamesPlayed = 0
        saveData()
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        saveData()
    }
}

