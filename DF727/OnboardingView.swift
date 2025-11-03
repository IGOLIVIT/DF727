//
//  OnboardingView.swift
//  DF727
//
//  Created by IGOR on 01/11/2025.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @Binding var isOnboardingComplete: Bool
    @State private var opacity: Double = 0
    
    let pages = [
        OnboardingPage(
            icon: "bolt.fill",
            title: "Test Your Reflexes",
            description: "Challenge your reaction speed with engaging mini-games"
        ),
        OnboardingPage(
            icon: "eye.fill",
            title: "Sharpen Your Focus",
            description: "Train your attention and improve concentration"
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            title: "Track Your Progress",
            description: "Earn Energy Points and watch your skills improve"
        )
    ]
    
    var body: some View {
        ZStack {
            Color(hex: "0D0D0D")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                .frame(height: 500)
                .onChange(of: currentPage) { _ in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        opacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            opacity = 1
                        }
                    }
                }
                
                Spacer()
                
                if currentPage == pages.count - 1 {
                    Button(action: {
                        withAnimation {
                            GameDataManager.shared.completeOnboarding()
                            isOnboardingComplete = true
                        }
                    }) {
                        Text("Start")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "0D0D0D"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "FFDD00"))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                    .transition(.opacity.combined(with: .scale))
                }
                
                if currentPage < pages.count - 1 {
                    Spacer()
                        .frame(height: 106)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                opacity = 1
            }
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: page.icon)
                .font(.system(size: 80, weight: .light))
                .foregroundColor(Color(hex: "FFDD00"))
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .opacity(isAnimating ? 1 : 0)
                .animation(.easeOut(duration: 0.6), value: isAnimating)
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: isAnimating)
                
                Text(page.description)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: isAnimating)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

