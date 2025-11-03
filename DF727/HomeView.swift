//
//  HomeView.swift
//  DF727
//
//  Created by IGOR on 01/11/2025.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var dataManager = GameDataManager.shared
    @State private var selectedGame: GameType? = nil
    @State private var showingStats = false
    @State private var animateCards = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0D0D0D")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "FFDD00"))
                                Text("\(dataManager.totalEnergyPoints) Energy Points")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(hex: "FFDD00"))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: "000000"))
                            .cornerRadius(20)
                        }
                        .padding(.top, 20)
                        
                        // Title
                        Text("Select Your Challenge")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                        
                        // Game Cards
                        VStack(spacing: 20) {
                            GameCard(
                                game: GameType.pulseTap,
                                isAnimating: animateCards
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedGame = .pulseTap
                                }
                            }
                            
                            GameCard(
                                game: GameType.focusShift,
                                isAnimating: animateCards
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedGame = .focusShift
                                }
                            }
                            
                            GameCard(
                                game: GameType.patternRecall,
                                isAnimating: animateCards
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedGame = .patternRecall
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Stats Button
                        Button(action: {
                            withAnimation {
                                showingStats = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 18))
                                Text("View Stats & Settings")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: "0D0D0D"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "FFDD00"))
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
                .background(
                    Group {
                        NavigationLink(
                            destination: PulseTapGameView(),
                            tag: .pulseTap,
                            selection: $selectedGame
                        ) { EmptyView() }
                        
                        NavigationLink(
                            destination: FocusShiftGameView(),
                            tag: .focusShift,
                            selection: $selectedGame
                        ) { EmptyView() }
                        
                        NavigationLink(
                            destination: PatternRecallGameView(),
                            tag: .patternRecall,
                            selection: $selectedGame
                        ) { EmptyView() }
                    }
                )
                .sheet(isPresented: $showingStats) {
                    StatsView()
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    animateCards = true
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

enum GameType: Identifiable, Hashable {
    case pulseTap
    case focusShift
    case patternRecall
    
    var id: String {
        switch self {
        case .pulseTap: return "pulseTap"
        case .focusShift: return "focusShift"
        case .patternRecall: return "patternRecall"
        }
    }
    
    var title: String {
        switch self {
        case .pulseTap: return "Pulse Tap"
        case .focusShift: return "Focus Shift"
        case .patternRecall: return "Pattern Recall"
        }
    }
    
    var description: String {
        switch self {
        case .pulseTap: return "Tap highlighted shapes, build combos, and climb levels!"
        case .focusShift: return "Track moving targets, avoid obstacles, grab bonuses!"
        case .patternRecall: return "Watch sequences and repeat them perfectly!"
        }
    }
    
    var icon: String {
        switch self {
        case .pulseTap: return "hand.tap.fill"
        case .focusShift: return "eye.fill"
        case .patternRecall: return "brain.head.profile"
        }
    }
    
    var color: Color {
        switch self {
        case .pulseTap: return Color(hex: "FFDD00")
        case .focusShift: return Color(hex: "FFDD00")
        case .patternRecall: return Color(hex: "FFDD00")
        }
    }
}

struct GameCard: View {
    let game: GameType
    let isAnimating: Bool
    @State private var isPulsing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: game.icon)
                    .font(.system(size: 32))
                    .foregroundColor(game.color)
                    .frame(width: 56, height: 56)
                    .background(Color(hex: "0D0D0D"))
                    .cornerRadius(12)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(game.color)
            }
            
            Text(game.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(game.description)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 160)
        .background(Color(hex: "000000"))
        .cornerRadius(20)
        .shadow(color: game.color.opacity(isPulsing ? 0.3 : 0.1), radius: isPulsing ? 15 : 8)
        .scaleEffect(isAnimating ? 1.0 : 0.9)
        .opacity(isAnimating ? 1 : 0)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

