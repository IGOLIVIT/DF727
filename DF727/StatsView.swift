//
//  StatsView.swift
//  DF727
//
//  Created by IGOR on 01/11/2025.
//

import SwiftUI

struct StatsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager = GameDataManager.shared
    @State private var showResetAlert = false
    @State private var animateStats = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0D0D0D")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Total Energy Points
                        VStack(spacing: 12) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Color(hex: "FFDD00"))
                                .scaleEffect(animateStats ? 1.0 : 0.8)
                                .opacity(animateStats ? 1 : 0)
                            
                            Text("Total Energy Points")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("\(dataManager.totalEnergyPoints)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(Color(hex: "FFDD00"))
                        }
                        .padding(.top, 32)
                        .padding(.bottom, 16)
                        
                        // Stats Grid
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                StatCard(
                                    title: "Games Played",
                                    value: "\(dataManager.gamesPlayed)",
                                    icon: "gamecontroller.fill",
                                    isAnimating: animateStats
                                )
                                
                                StatCard(
                                    title: "Current Streak",
                                    value: "\(dataManager.currentStreak)",
                                    icon: "flame.fill",
                                    isAnimating: animateStats
                                )
                            }
                            
                            HStack(spacing: 16) {
                                StatCard(
                                    title: "Pulse Tap Best",
                                    value: "\(dataManager.pulseTapBestScore)",
                                    icon: "hand.tap.fill",
                                    isAnimating: animateStats
                                )
                                
                                StatCard(
                                    title: "Focus Shift Best",
                                    value: "\(dataManager.focusShiftBestScore)",
                                    icon: "eye.fill",
                                    isAnimating: animateStats
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Achievements Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Achievements")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 12) {
                                AchievementRow(
                                    title: "First Steps",
                                    description: "Play your first game",
                                    isUnlocked: dataManager.gamesPlayed >= 1,
                                    icon: "star.fill"
                                )
                                
                                AchievementRow(
                                    title: "Energized",
                                    description: "Earn 100 Energy Points",
                                    isUnlocked: dataManager.totalEnergyPoints >= 100,
                                    icon: "bolt.fill"
                                )
                                
                                AchievementRow(
                                    title: "Dedicated",
                                    description: "Play 10 games",
                                    isUnlocked: dataManager.gamesPlayed >= 10,
                                    icon: "flame.fill"
                                )
                                
                                AchievementRow(
                                    title: "Master",
                                    description: "Earn 500 Energy Points",
                                    isUnlocked: dataManager.totalEnergyPoints >= 500,
                                    icon: "crown.fill"
                                )
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.top, 16)
                        
                        // Settings Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Settings")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                            
                            Button(action: {
                                showResetAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 18))
                                    Text("Reset Progress")
                                        .font(.system(size: 17, weight: .semibold))
                                    Spacer()
                                }
                                .foregroundColor(.red)
                                .padding(20)
                                .background(Color(hex: "000000"))
                                .cornerRadius(16)
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Stats & Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .alert("Reset Progress", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    withAnimation {
                        dataManager.resetProgress()
                    }
                }
            } message: {
                Text("Are you sure you want to reset all your progress? This action cannot be undone.")
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateStats = true
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let isAnimating: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "FFDD00"))
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 120)
        .background(Color(hex: "000000"))
        .cornerRadius(16)
        .scaleEffect(isAnimating ? 1.0 : 0.9)
        .opacity(isAnimating ? 1 : 0)
    }
}

struct AchievementRow: View {
    let title: String
    let description: String
    let isUnlocked: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color(hex: "FFDD00") : Color(hex: "000000"))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isUnlocked ? Color(hex: "0D0D0D") : .white.opacity(0.3))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(isUnlocked ? .white : .white.opacity(0.5))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "FFDD00"))
            }
        }
        .padding(16)
        .background(Color(hex: "000000"))
        .cornerRadius(16)
    }
}

