//
//  FocusShiftGameView.swift
//  DF727
//
//  Created by IGOR on 01/11/2025.
//

import SwiftUI

struct FocusShiftGameView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager = GameDataManager.shared
    
    @State private var score = 0
    @State private var timeRemaining = 60
    @State private var isGameActive = false
    @State private var showResult = false
    @State private var earnedPoints = 0
    @State private var gameTimer: Timer? = nil
    @State private var movingObjects: [MovingObject] = []
    @State private var obstacles: [Obstacle] = []
    @State private var bonusItems: [BonusItem] = []
    @State private var targetColor: ObjectColor? = nil
    @State private var successAnimation = false
    @State private var isPaused = false
    @State private var showExitConfirmation = false
    
    // New mechanics
    @State private var level = 1
    @State private var objectSpeed: CGFloat = 2.0
    @State private var perfectHits = 0
    @State private var multiplier = 1
    @State private var bonusesCollected = 0
    @State private var showMultiplierAnimation = false
    
    let colors: [ObjectColor] = [.yellow, .red, .blue, .green, .purple]
    
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
                            Image(systemName: "eye.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color(hex: "FFDD00"))
                            
                            Text("Focus Shift")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Track moving objects in the center zone. Avoid obstacles and grab bonuses!")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            VStack(spacing: 12) {
                                FeatureRow(icon: "target", text: "Hit targets in center zone")
                                FeatureRow(icon: "xmark.circle", text: "Avoid obstacles")
                                FeatureRow(icon: "gift.fill", text: "Collect bonus multipliers")
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
                    
                    // Level and Multiplier
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
                        
                        if multiplier > 1 {
                            HStack(spacing: 8) {
                                Image(systemName: "multiply.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.purple)
                                Text("\(multiplier)x")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.purple)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: "000000"))
                            .cornerRadius(12)
                            .scaleEffect(showMultiplierAnimation ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showMultiplierAnimation)
                        }
                    }
                    .padding(.top, 16)
                    
                    // Target indicator
                    if let target = targetColor {
                        VStack(spacing: 8) {
                            Text("Find the")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(target.color)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                Text(target.name)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(hex: "FFDD00"))
                            }
                        }
                        .padding(.top, 12)
                    }
                    
                    // Game Area
                    GeometryReader { geometry in
                        ZStack {
                            // Center target zone
                            Circle()
                                .stroke(Color(hex: "FFDD00").opacity(0.4), lineWidth: 3)
                                .frame(width: 140, height: 140)
                                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            
                            Circle()
                                .fill(Color(hex: "FFDD00").opacity(0.05))
                                .frame(width: 140, height: 140)
                                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            
                            // Obstacles
                            ForEach(obstacles) { obstacle in
                                ObstacleView(obstacle: obstacle)
                                    .position(obstacle.position)
                            }
                            
                            // Moving objects
                            ForEach(movingObjects) { object in
                                MovingObjectView(object: object, isTarget: object.color == targetColor)
                                    .position(object.position)
                                    .onTapGesture {
                                        handleObjectTap(object: object, geometry: geometry)
                                    }
                            }
                            
                            // Bonus items
                            ForEach(bonusItems) { bonus in
                                BonusItemView(bonus: bonus)
                                    .position(bonus.position)
                                    .onTapGesture {
                                        handleBonusTap(bonus: bonus, geometry: geometry)
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
                            Text("Excellent Focus!")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 16) {
                                StatRow(label: "Final Score", value: "\(score)", highlight: true)
                                StatRow(label: "Perfect Hits", value: "\(perfectHits)")
                                StatRow(label: "Bonuses Collected", value: "\(bonusesCollected)")
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
                                    Text("Multiplier:")
                                    Spacer()
                                    Text("\(multiplier)x")
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
        level = 1
        objectSpeed = 2.0
        perfectHits = 0
        multiplier = 1
        bonusesCollected = 0
        
        spawnObjects()
        spawnObstacles()
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if !isPaused {
                timeRemaining -= 1
                if timeRemaining <= 0 {
                    endGame()
                }
                
                // Spawn bonus every 10 seconds
                if timeRemaining % 10 == 0 {
                    spawnBonus()
                }
                
                // Level up every 15 seconds
                if timeRemaining % 15 == 0 && timeRemaining != 60 {
                    levelUp()
                }
            }
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            if !isGameActive {
                timer.invalidate()
                return
            }
            if !isPaused {
                updateObjectPositions()
            }
        }
    }
    
    func spawnObjects() {
        targetColor = colors.randomElement()
        movingObjects.removeAll()
        
        let screenWidth = UIScreen.main.bounds.width - 80
        let screenHeight = UIScreen.main.bounds.height - 300
        let numObjects = min(8, 4 + level)
        let numTargets = level >= 4 ? 2 : 1
        
        for i in 0..<numObjects {
            let color = i < numTargets ? targetColor! : colors.filter { $0 != targetColor }.randomElement()!
            
            let startX = CGFloat.random(in: 40...(screenWidth - 40))
            let startY = CGFloat.random(in: 40...(screenHeight - 40))
            
            let speed = objectSpeed + CGFloat.random(in: -0.5...0.5)
            let velocityX = CGFloat.random(in: -speed...speed)
            let velocityY = CGFloat.random(in: -speed...speed)
            
            movingObjects.append(MovingObject(
                color: color,
                position: CGPoint(x: startX, y: startY),
                velocity: CGPoint(x: velocityX, y: velocityY)
            ))
        }
    }
    
    func spawnObstacles() {
        obstacles.removeAll()
        
        if level < 3 { return }
        
        let screenWidth = UIScreen.main.bounds.width - 80
        let screenHeight = UIScreen.main.bounds.height - 300
        let numObstacles = min(4, level - 2)
        
        for _ in 0..<numObstacles {
            let x = CGFloat.random(in: 40...(screenWidth - 40))
            let y = CGFloat.random(in: 40...(screenHeight - 40))
            let velocityX = CGFloat.random(in: -1.5...1.5)
            let velocityY = CGFloat.random(in: -1.5...1.5)
            
            obstacles.append(Obstacle(
                position: CGPoint(x: x, y: y),
                velocity: CGPoint(x: velocityX, y: velocityY)
            ))
        }
    }
    
    func spawnBonus() {
        let screenWidth = UIScreen.main.bounds.width - 80
        let screenHeight = UIScreen.main.bounds.height - 300
        
        let x = CGFloat.random(in: 60...(screenWidth - 60))
        let y = CGFloat.random(in: 60...(screenHeight - 60))
        
        bonusItems.append(BonusItem(position: CGPoint(x: x, y: y)))
        
        // Remove after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            bonusItems.removeAll { $0.position.x == x && $0.position.y == y }
        }
    }
    
    func levelUp() {
        level += 1
        objectSpeed = min(4.0, objectSpeed + 0.3)
        spawnObjects()
        if level >= 3 {
            spawnObstacles()
        }
    }
    
    func updateObjectPositions() {
        let screenWidth = UIScreen.main.bounds.width - 80
        let screenHeight = UIScreen.main.bounds.height - 300
        
        for i in 0..<movingObjects.count {
            var obj = movingObjects[i]
            obj.position.x += obj.velocity.x
            obj.position.y += obj.velocity.y
            
            if obj.position.x <= 30 || obj.position.x >= screenWidth - 30 {
                obj.velocity.x *= -1
            }
            if obj.position.y <= 30 || obj.position.y >= screenHeight - 30 {
                obj.velocity.y *= -1
            }
            
            movingObjects[i] = obj
        }
        
        for i in 0..<obstacles.count {
            var obs = obstacles[i]
            obs.position.x += obs.velocity.x
            obs.position.y += obs.velocity.y
            
            if obs.position.x <= 30 || obs.position.x >= screenWidth - 30 {
                obs.velocity.x *= -1
            }
            if obs.position.y <= 30 || obs.position.y >= screenHeight - 30 {
                obs.velocity.y *= -1
            }
            
            obstacles[i] = obs
        }
    }
    
    func handleObjectTap(object: MovingObject, geometry: GeometryProxy) {
        if isPaused { return }
        
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        let distance = sqrt(pow(object.position.x - centerX, 2) + pow(object.position.y - centerY, 2))
        
        if distance < 70 && object.color == targetColor {
            let points = 20 * multiplier
            score += points
            perfectHits += 1
            spawnObjects()
            if level >= 3 && obstacles.count < level - 1 {
                spawnObstacles()
            }
        } else if object.color != targetColor {
            score = max(0, score - 10)
            multiplier = 1
        }
    }
    
    func handleBonusTap(bonus: BonusItem, geometry: GeometryProxy) {
        if isPaused { return }
        
        multiplier = min(5, multiplier + 1)
        bonusesCollected += 1
        bonusItems.removeAll { $0.id == bonus.id }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showMultiplierAnimation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showMultiplierAnimation = false
        }
        
        // Reset multiplier after 8 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            if multiplier > 1 {
                multiplier = max(1, multiplier - 1)
            }
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
        
        let levelBonus = level * 15
        let bonusMultiplier = bonusesCollected * 10
        earnedPoints = (score + levelBonus + bonusMultiplier) * 2
        
        dataManager.addEnergyPoints(earnedPoints)
        dataManager.updateFocusShiftScore(score)
        if perfectHits >= 10 {
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
        targetColor = nil
        movingObjects.removeAll()
        obstacles.removeAll()
        bonusItems.removeAll()
        isGameActive = false
        showResult = false
        successAnimation = false
        level = 1
        objectSpeed = 2.0
        perfectHits = 0
        multiplier = 1
        bonusesCollected = 0
    }
}

enum ObjectColor: CaseIterable {
    case yellow, red, blue, green, purple
    
    var name: String {
        switch self {
        case .yellow: return "Yellow"
        case .red: return "Red"
        case .blue: return "Blue"
        case .green: return "Green"
        case .purple: return "Purple"
        }
    }
    
    var color: Color {
        switch self {
        case .yellow: return Color(hex: "FFDD00")
        case .red: return .red
        case .blue: return Color.blue
        case .green: return .green
        case .purple: return .purple
        }
    }
}

struct MovingObject: Identifiable {
    let id = UUID()
    let color: ObjectColor
    var position: CGPoint
    var velocity: CGPoint
}

struct Obstacle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
}

struct BonusItem: Identifiable {
    let id = UUID()
    var position: CGPoint
}

struct MovingObjectView: View {
    let object: MovingObject
    let isTarget: Bool
    @State private var isPulsing = false
    
    var body: some View {
        Circle()
            .fill(object.color.color)
            .frame(width: 45, height: 45)
            .overlay(
                Circle()
                    .stroke(isTarget ? Color.white : Color.clear, lineWidth: isTarget ? 3 : 0)
            )
            .shadow(color: isTarget ? object.color.color.opacity(0.8) : object.color.color.opacity(0.3), radius: isPulsing && isTarget ? 15 : 8)
            .scaleEffect(isPulsing && isTarget ? 1.1 : 1.0)
            .onAppear {
                if isTarget {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
            }
    }
}

struct ObstacleView: View {
    let obstacle: Obstacle
    @State private var isRotating = false
    
    var body: some View {
        Image(systemName: "xmark.circle.fill")
            .font(.system(size: 40))
            .foregroundColor(.red.opacity(0.7))
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    isRotating = true
                }
            }
    }
}

struct BonusItemView: View {
    let bonus: BonusItem
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.purple.opacity(0.3))
                .frame(width: 50, height: 50)
            
            Image(systemName: "gift.fill")
                .font(.system(size: 28))
                .foregroundColor(.purple)
        }
        .scaleEffect(isPulsing ? 1.2 : 1.0)
        .shadow(color: .purple.opacity(0.6), radius: 15)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}
