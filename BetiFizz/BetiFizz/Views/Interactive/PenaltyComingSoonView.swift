//
//  PenaltyComingSoonView.swift
//  BetiFizz
//

import SwiftUI

struct PenaltyComingSoonView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LiquidGlassScreenBackground()

            VStack(spacing: 32) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    BetiFizzTheme.primaryGreen.opacity(0.3),
                                    BetiFizzTheme.primaryGreen.opacity(0.06),
                                    Color.clear,
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 120
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 1)

                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial.opacity(0.55))
                            .frame(width: 120, height: 120)
                            .overlay {
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.3), BetiFizzTheme.primaryGreen.opacity(0.4)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.2
                                    )
                            }
                        Image(systemName: "soccerball")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundStyle(BetiFizzTheme.primaryGreen)
                    }
                }

                VStack(spacing: 14) {
                    Text("Penalty Kick")
                        .font(.title.weight(.bold))
                        .foregroundStyle(BetiFizzTheme.textPrimary)
                    Text("Coming Soon")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(BetiFizzTheme.primaryGreen)
                    Text("A penalty shootout mini-game is on the way.\nStay tuned!")
                        .font(.body)
                        .foregroundStyle(BetiFizzTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                }

                Spacer()

                Button { dismiss() } label: {
                    Text("Back")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(LiquidGlassPrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
    }
}

#Preview {
    PenaltyComingSoonView()
}
