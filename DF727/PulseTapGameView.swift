//
//  PulseTapGameView.swift
//  DF727
//
//  Created by IGOR on 01/11/2025.
//

import SwiftUI

struct PulseTapGameView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager = GameDataManager.shared
    
    @State private var score = 0
    @State private var targetShape: ShapeType? = nil
    @State private var displayedShapes: [DisplayShape] = []
    @State private var timeRemaining = 60
    @State private var isGameActive = false
    @State private var showResult = false
    @State private var earnedPoints = 0
    @State private var gameTimer: Timer? = nil
    @State private var successAnimation = false
    @State private var isPaused = false
    @State private var showExitConfirmation = false
    
    // New mechanics
    @State private var combo = 0
    @State private var maxCombo = 0
    @State private var level = 1
    @State private var shapesPerRound = 4
    @State private var timeBonus = 0
    @State private var perfectTaps = 0
    @State private var showComboAnimation = false
    @State private var shapeSpeed: Double = 1.0
    
    let shapes: [ShapeType] = [.circle, .square, .triangle, .diamond, .star, .heart]
    
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
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color(hex: "FFDD00"))
                            
                            Text("Pulse Tap")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Tap highlighted shapes quickly to build combos! Wrong taps break your streak.")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            // Game features
                            VStack(spacing: 12) {
                                FeatureRow(icon: "flame.fill", text: "Build combo chains")
                                FeatureRow(icon: "bolt.fill", text: "Progressive difficulty")
                                FeatureRow(icon: "star.fill", text: "Special bonus shapes")
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
                    // Header with controls
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
                    
                    // Level and Combo display
                    HStack(spacing: 20) {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 14))
                            Text("Level \(level)")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: "000000"))
                        .cornerRadius(12)
                        
                        if combo > 0 {
                            HStack(spacing: 8) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(combo >= 5 ? .orange : Color(hex: "FFDD00"))
                                Text("x\(combo)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(combo >= 5 ? .orange : Color(hex: "FFDD00"))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: "000000"))
                            .cornerRadius(12)
                            .scaleEffect(showComboAnimation ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showComboAnimation)
                        }
                    }
                    .padding(.top, 16)
                    
                    // Target indicator
                    if let target = targetShape {
                        VStack(spacing: 8) {
                            Text("Tap the")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                            HStack(spacing: 8) {
                                target.icon
                                    .font(.system(size: 28))
                                    .foregroundColor(target.isSpecial ? .orange : Color(hex: "FFDD00"))
                                Text(target.name)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(target.isSpecial ? .orange : Color(hex: "FFDD00"))
                                if target.isSpecial {
                                    Text("2x")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.2))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.top, 12)
                    }
                    
                    // Game Area
                    GeometryReader { geometry in
                        ZStack {
                            ForEach(displayedShapes) { shape in
                                ShapeView(shape: shape, isTarget: shape.type == targetShape)
                                    .position(shape.position)
                                    .onTapGesture {
                                        handleShapeTap(shape: shape)
                                    }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
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
                            Text("Amazing!")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 16) {
                                StatRow(label: "Final Score", value: "\(score)", highlight: true)
                                StatRow(label: "Max Combo", value: "x\(maxCombo)")
                                StatRow(label: "Perfect Taps", value: "\(perfectTaps)")
                                StatRow(label: "Level Reached", value: "\(level)")
                                
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
                                    Text("Combo:")
                                    Spacer()
                                    Text("x\(combo)")
                                        .foregroundColor(Color(hex: "FFDD00"))
                                }
                                HStack {
                                    Text("Level:")
                                    Spacer()
                                    Text("\(level)")
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
        timeRemaining = 60
        isGameActive = true
        showResult = false
        successAnimation = false
        combo = 0
        maxCombo = 0
        level = 1
        shapesPerRound = 4
        perfectTaps = 0
        shapeSpeed = 1.0
        
        spawnNextRound()
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if !isPaused {
                timeRemaining -= 1
                if timeRemaining <= 0 {
                    endGame()
                }
            }
        }
    }
    
    func spawnNextRound() {
        // Progressive difficulty
        if score > 0 && score % 100 == 0 {
            levelUp()
        }
        
        // 20% chance for special shape at higher levels
        let useSpecialShape = level >= 3 && Int.random(in: 1...5) == 1
        targetShape = useSpecialShape ? shapes.filter { $0.isSpecial }.randomElement() : shapes.filter { !$0.isSpecial }.randomElement()
        displayedShapes.removeAll()
        
        let positions = generateRandomPositions(count: shapesPerRound)
        let numTargets = level >= 5 ? 2 : 1
        
        for (index, position) in positions.enumerated() {
            let shapeType: ShapeType
            if index < numTargets {
                shapeType = targetShape!
            } else {
                shapeType = shapes.filter { $0 != targetShape && !$0.isSpecial }.randomElement()!
            }
            displayedShapes.append(DisplayShape(type: shapeType, position: position))
        }
        
        // Shuffle to randomize target positions
        displayedShapes.shuffle()
    }
    
    func levelUp() {
        level += 1
        shapesPerRound = min(8, shapesPerRound + 1)
        
        // Visual feedback
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showComboAnimation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showComboAnimation = false
        }
    }
    
    func generateRandomPositions(count: Int) -> [CGPoint] {
        var positions: [CGPoint] = []
        let screenWidth = UIScreen.main.bounds.width - 100
        let screenHeight = UIScreen.main.bounds.height - 400
        
        for _ in 0..<count {
            var newPosition: CGPoint
            var attempts = 0
            
            repeat {
                newPosition = CGPoint(
                    x: CGFloat.random(in: 50...(screenWidth - 50)),
                    y: CGFloat.random(in: 50...(screenHeight - 50))
                )
                attempts += 1
            } while positions.contains(where: { distance($0, newPosition) < 80 }) && attempts < 30
            
            positions.append(newPosition)
        }
        
        return positions
    }
    
    func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))
    }
    
    func handleShapeTap(shape: DisplayShape) {
        if isPaused { return }
        
        if shape.type == targetShape {
            // Correct tap
            let basePoints = shape.type.isSpecial ? 20 : 10
            let comboBonus = combo >= 5 ? 5 : 0
            score += basePoints + comboBonus
            
            combo += 1
            maxCombo = max(maxCombo, combo)
            perfectTaps += 1
            
            // Visual feedback
            if combo % 5 == 0 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    showComboAnimation = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showComboAnimation = false
                }
            }
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                spawnNextRound()
            }
        } else {
            // Wrong tap
            score = max(0, score - 5)
            combo = 0
        }
    }
    
    func togglePause() {
        isPaused.toggle()
        if isPaused {
            gameTimer?.invalidate()
        } else {
            gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if !isPaused {
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
        
        // Calculate bonus
        let comboBonus = maxCombo * 2
        let levelBonus = level * 10
        earnedPoints = (score + comboBonus + levelBonus) * 2
        
        dataManager.addEnergyPoints(earnedPoints)
        dataManager.updatePulseTapScore(score)
        if combo >= 10 {
            dataManager.incrementStreak()
        }
        
        showResult = true
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
            successAnimation = true
        }
    }
    
    func resetGame() {
        score = 0
        timeRemaining = 60
        targetShape = nil
        displayedShapes.removeAll()
        isGameActive = false
        showResult = false
        successAnimation = false
        combo = 0
        maxCombo = 0
        level = 1
        shapesPerRound = 4
        perfectTaps = 0
    }
}

enum ShapeType: String, CaseIterable, Equatable, Hashable {
    case circle, square, triangle, diamond, star, heart
    
    var name: String {
        rawValue.capitalized
    }
    
    var icon: Image {
        switch self {
        case .circle: return Image(systemName: "circle.fill")
        case .square: return Image(systemName: "square.fill")
        case .triangle: return Image(systemName: "triangle.fill")
        case .diamond: return Image(systemName: "diamond.fill")
        case .star: return Image(systemName: "star.fill")
        case .heart: return Image(systemName: "heart.fill")
        }
    }
    
    var isSpecial: Bool {
        self == .star || self == .heart
    }
}

struct DisplayShape: Identifiable {
    let id = UUID()
    let type: ShapeType
    let position: CGPoint
}

struct ShapeView: View {
    let shape: DisplayShape
    let isTarget: Bool
    @State private var isPulsing = false
    
    var body: some View {
        shape.type.icon
            .font(.system(size: shape.type.isSpecial ? 55 : 50))
            .foregroundColor(isTarget ? (shape.type.isSpecial ? .orange : Color(hex: "FFDD00")) : .white.opacity(0.25))
            .scaleEffect(isPulsing && isTarget ? 1.15 : 1.0)
            .shadow(color: isTarget ? (shape.type.isSpecial ? Color.orange.opacity(0.8) : Color(hex: "FFDD00").opacity(0.6)) : .clear, radius: isPulsing ? 25 : 12)
            .onAppear {
                if isTarget {
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
            }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "FFDD00"))
                .frame(width: 24)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    var highlight: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: highlight ? 24 : 18, weight: highlight ? .bold : .semibold))
                .foregroundColor(highlight ? Color(hex: "FFDD00") : .white)
        }
    }
}
