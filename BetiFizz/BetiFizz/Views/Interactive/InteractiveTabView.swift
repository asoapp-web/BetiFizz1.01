//
//  InteractiveTabView.swift
//  BetiFizz
//

import SwiftUI

struct InteractiveTabView: View {
    @State private var showQuiz = false
    @State private var showPenalty = false

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassScreenBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        modeCard(
                            symbol: "questionmark.circle.fill",
                            title: "Quiz",
                            detail: "Daily challenges & practice rounds — Easy, Medium, Hard.",
                            badge: nil,
                            action: { showQuiz = true }
                        )

                        modeCard(
                            symbol: "soccerball",
                            title: "Penalty Kick",
                            detail: "Test your reflexes in a penalty shootout mini-game.",
                            badge: "COMING SOON",
                            action: { showPenalty = true }
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Interactive")
            .betiFizzNavigationChrome()
        }
        .fullScreenCover(isPresented: $showQuiz) {
            QuizFullScreenView()
        }
        .fullScreenCover(isPresented: $showPenalty) {
            PenaltyComingSoonView()
        }
    }

    private func modeCard(symbol: String, title: String, detail: String, badge: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            LiquidGlassCard(cornerRadius: 22, highlightOpacity: 0.3) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(BetiFizzTheme.primaryGreen.opacity(0.15))
                            .frame(width: 56, height: 56)
                        Image(systemName: symbol)
                            .font(.title2)
                            .foregroundStyle(BetiFizzTheme.primaryGreen)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 8) {
                            Text(title)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(BetiFizzTheme.textPrimary)
                            if let badge {
                                Text(badge)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(BetiFizzTheme.primaryGreen)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(BetiFizzTheme.primaryGreen.opacity(0.14))
                                    .clipShape(Capsule())
                            }
                        }
                        Text(detail)
                            .font(.subheadline)
                            .foregroundStyle(BetiFizzTheme.textSecondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BetiFizzTheme.textSecondary.opacity(0.55))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    InteractiveTabView()
}
