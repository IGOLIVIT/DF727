//
//  MemoryFlashGameView.swift
//  DF727
//
//  Created by IGOR on 01/11/2025.
//

import SwiftUI

struct MemoryFlashGameView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager = GameDataManager.shared
    
    @State private var score = 0
    @State private var timeRemaining = 45
    @State private var isGameActive = false
    @State private var showResult = false
    @State private var earnedPoints = 0
    @State private var gameTimer: Timer? = nil
    @State private var successAnimation = false
    @State private var isPaused = false
    @State private var showExitConfirmation = false
    
    // Game mechanics
    @State private var sequence: [Int] = []
    @State private var playerSequence: [Int] = []
    @State private var isShowingSequence = false
    @State private var currentRound = 1
    @State private var sequenceLength = 3
    @State private var flashSpeed: Double = 0.6
    @State private var perfectRounds = 0
    @State private var currentlyFlashing: Int? = nil
    
    let gridSize = 9 // 3x3 grid
    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    
    var body: some View {
        ZStack {
            Color(hex: "0D0D0D")
                .ignoresSafeArea()
            
            if !isGameActive && !showResult {
                // Start Screen
                VStack(spacing: 0) {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 17, weight: .medium))
                            }
                            .foregroundColor(Color(hex: "FFDD00"))
                        }
                        .padding(.leading, 24)
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    VStack(spacing: 32) {
                        VStack(spacing: 16) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 60))
                                .foregroundColor(Color(hex: "FFDD00"))
                            
                            Text("Pattern Recall")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Watch the sequence and repeat it! Patterns get longer and faster.")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            VStack(spacing: 12) {
                                FeatureRow(icon: "eye.fill", text: "Watch the pattern")
                                FeatureRow(icon: "hand.tap.fill", text: "Repeat the sequence")
                                FeatureRow(icon: "bolt.fill", text: "Speed increases each round")
                            }
                            .padding(.top, 8)
                        }
                        
                        Button(action: startGame) {
                            Text("Start Game")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "0D0D0D"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color(hex: "FFDD00"))
                                .cornerRadius(16)
                        }
                        .padding(.horizontal, 32)
                    }
                    
                    Spacer()
                }
            } else if isGameActive {
                // Game Screen
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: {
                            showExitConfirmation = true
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color(hex: "000000"))
                                .cornerRadius(12)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Text("Score")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                            Text("\(score)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(hex: "FFDD00"))
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Text("Time")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                            Text("\(timeRemaining)s")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(timeRemaining <= 10 ? .red : .white)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            togglePause()
                        }) {
                            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color(hex: "000000"))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Round info
                    VStack(spacing: 8) {
                        HStack(spacing: 20) {
                            HStack(spacing: 8) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 14))
                                Text("Round \(currentRound)")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: "000000"))
                            .cornerRadius(12)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "square.grid.3x3.fill")
                                    .font(.system(size: 14))
                                Text("\(sequenceLength) tiles")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: "FFDD00"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: "000000"))
                            .cornerRadius(12)
                        }
                        
                        Text(isShowingSequence ? "Watch carefully..." : "Your turn!")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isShowingSequence ? .orange : Color(hex: "FFDD00"))
                            .padding(.top, 4)
                    }
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // Game Grid
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(0..<gridSize, id: \.self) { index in
                            MemoryTile(
                                index: index,
                                isFlashing: currentlyFlashing == index,
                                isDisabled: isShowingSequence
                            )
                            .onTapGesture {
                                handleTileTap(index: index)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Progress indicator
                    if !isShowingSequence && playerSequence.count > 0 {
                        HStack(spacing: 8) {
                            ForEach(0..<sequenceLength, id: \.self) { i in
                                Circle()
                                    .fill(i < playerSequence.count ? Color(hex: "FFDD00") : Color.white.opacity(0.3))
                                    .frame(width: 12, height: 12)
                            }
                        }
                        .padding(.bottom, 32)
                    } else {
                        Spacer()
                            .frame(height: 56)
                    }
                }
            } else if showResult {
                // Result Screen
                ScrollView {
                    VStack(spacing: 32) {
                        if successAnimation {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(Color(hex: "FFDD00"))
                                .scaleEffect(successAnimation ? 1.0 : 0.5)
                                .opacity(successAnimation ? 1 : 0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: successAnimation)
                        }
                        
                        VStack(spacing: 16) {
                            Text("Excellent Recall!")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 16) {
                                StatRow(label: "Final Score", value: "\(score)", highlight: true)
                                StatRow(label: "Rounds Completed", value: "\(currentRound - 1)")
                                StatRow(label: "Perfect Rounds", value: "\(perfectRounds)")
                                StatRow(label: "Longest Sequence", value: "\(sequenceLength - 1)")
                                
                                Divider()
                                    .background(Color.white.opacity(0.3))
                                    .padding(.vertical, 8)
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "bolt.fill")
                                        .foregroundColor(Color(hex: "FFDD00"))
                                    Text("Earned \(earnedPoints) Energy Points")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color(hex: "FFDD00"))
                                }
                            }
                            .padding(24)
                            .background(Color(hex: "000000"))
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(spacing: 16) {
                            Button(action: {
                                resetGame()
                                startGame()
                            }) {
                                Text("Play Again")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(hex: "0D0D0D"))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(hex: "FFDD00"))
                                    .cornerRadius(16)
                            }
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Text("Back to Hub")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(hex: "000000"))
                                    .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 32)
                }
            }
            
            // Pause overlay
            if isPaused && isGameActive && !showResult {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 32) {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(Color(hex: "FFDD00"))
                            
                            Text("Paused")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Score:")
                                    Spacer()
                                    Text("\(score)")
                                        .foregroundColor(Color(hex: "FFDD00"))
                                }
                                HStack {
                                    Text("Round:")
                                    Spacer()
                                    Text("\(currentRound)")
                                        .foregroundColor(Color(hex: "FFDD00"))
                                }
                            }
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                            .padding(20)
                            .background(Color(hex: "000000"))
                            .cornerRadius(16)
                            
                            VStack(spacing: 16) {
                                Button(action: {
                                    togglePause()
                                }) {
                                    Text("Resume")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color(hex: "0D0D0D"))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(Color(hex: "FFDD00"))
                                        .cornerRadius(16)
                                }
                                
                                Button(action: {
                                    showExitConfirmation = true
                                }) {
                                    Text("Exit Game")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(Color(hex: "000000"))
                                        .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal, 32)
                        }
                    )
            }
        }
        .navigationBarBackButtonHidden(isGameActive)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Exit Game?", isPresented: $showExitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Exit", role: .destructive) {
                gameTimer?.invalidate()
                dismiss()
            }
        } message: {
            Text("Your progress will not be saved.")
        }
        .onDisappear {
            gameTimer?.invalidate()
        }
    }
    
    func startGame() {
        score = 0
        timeRemaining = 45
        isGameActive = true
        showResult = false
        successAnimation = false
        currentRound = 1
        sequenceLength = 3
        flashSpeed = 0.6
        perfectRounds = 0
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if !isPaused && !isShowingSequence {
                timeRemaining -= 1
                if timeRemaining <= 0 {
                    endGame()
                }
            }
        }
        
        startNewRound()
    }
    
    func startNewRound() {
        playerSequence.removeAll()
        sequence = (0..<sequenceLength).map { _ in Int.random(in: 0..<gridSize) }
        showSequence()
    }
    
    func showSequence() {
        isShowingSequence = true
        
        var delay = 0.5
        for (index, tile) in sequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                currentlyFlashing = tile
            }
            delay += flashSpeed
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                currentlyFlashing = nil
            }
            delay += flashSpeed * 0.5
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.5) {
            isShowingSequence = false
        }
    }
    
    func handleTileTap(index: Int) {
        if isShowingSequence || isPaused { return }
        
        playerSequence.append(index)
        currentlyFlashing = index
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            currentlyFlashing = nil
        }
        
        // Check if player made a mistake
        if playerSequence.last != sequence[playerSequence.count - 1] {
            // Wrong tile
            score = max(0, score - 10)
            startNewRound()
            return
        }
        
        // Check if sequence is complete
        if playerSequence.count == sequence.count {
            // Correct sequence!
            let points = sequenceLength * 10
            score += points
            perfectRounds += 1
            
            // Next round
            currentRound += 1
            sequenceLength += 1
            flashSpeed = max(0.3, flashSpeed - 0.05)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startNewRound()
            }
        }
    }
    
    func togglePause() {
        isPaused.toggle()
        if isPaused {
            gameTimer?.invalidate()
        } else {
            gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if !isPaused && !isShowingSequence {
                    timeRemaining -= 1
                    if timeRemaining <= 0 {
                        endGame()
                    }
                }
            }
        }
    }
    
    func endGame() {
        gameTimer?.invalidate()
        isGameActive = false
        
        let roundBonus = (currentRound - 1) * 15
        earnedPoints = (score + roundBonus) * 2
        
        dataManager.addEnergyPoints(earnedPoints)
        if perfectRounds >= 5 {
            dataManager.incrementStreak()
        }
        
        showResult = true
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
            successAnimation = true
        }
    }
    
    func resetGame() {
        score = 0
        timeRemaining = 45
        isGameActive = false
        showResult = false
        successAnimation = false
        sequence.removeAll()
        playerSequence.removeAll()
        isShowingSequence = false
        currentRound = 1
        sequenceLength = 3
        flashSpeed = 0.6
        perfectRounds = 0
        currentlyFlashing = nil
    }
}

struct MemoryTile: View {
    let index: Int
    let isFlashing: Bool
    let isDisabled: Bool
    @State private var isPressed = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(isFlashing ? Color(hex: "FFDD00") : Color(hex: "000000"))
            .frame(height: 90)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "FFDD00").opacity(0.3), lineWidth: 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: isFlashing ? Color(hex: "FFDD00").opacity(0.6) : .clear, radius: 15)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFlashing)
            .opacity(isDisabled ? 0.6 : 1.0)
            .onTapGesture {
                if !isDisabled {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        isPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPressed = false
                    }
                }
            }
    }
}

