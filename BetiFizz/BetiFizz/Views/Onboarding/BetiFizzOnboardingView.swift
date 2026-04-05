//
//  BetiFizzOnboardingView.swift
//  BetiFizz
//

import SwiftUI

struct BetiFizzOnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0

    private let slides: [(symbol: String, title: String, detail: String)] = [
        (
            "sportscourt.fill",
            "Fixtures that matter",
            "Browse matches in your date window, filter by league, and see live games first."
        ),
        (
            "star.fill",
            "Star teams, not IDs",
            "Save clubs to Favorites with crests and the next or last fixture we already have loaded."
        ),
        (
            "note.text",
            "Notes with context",
            "Jot thoughts and link a match or team — your picks stay tied to real fixtures."
        ),
        (
            "questionmark.circle.fill",
            "Quiz your knowledge",
            "Quick football trivia with streaks — dip in anytime from the Quiz tab."
        ),
    ]

    var body: some View {
        ZStack {
            LiquidGlassScreenBackground()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Skip") { onFinish() }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(BetiFizzTheme.textSecondary)
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 8)

                TabView(selection: $page) {
                    ForEach(slides.indices, id: \.self) { i in
                        slide(symbol: slides[i].symbol, title: slides[i].title, detail: slides[i].detail)
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                VStack(spacing: 14) {
                    if page < slides.count - 1 {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                                page = min(page + 1, slides.count - 1)
                            }
                        } label: {
                            Text("Continue")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(LiquidGlassPrimaryButtonStyle())
                    } else {
                        Button {
                            onFinish()
                        } label: {
                            Text("Get started")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(LiquidGlassPrimaryButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
                .padding(.top, 8)
            }
        }
    }

    private func slide(symbol: String, title: String, detail: String) -> some View {
        VStack(spacing: 28) {
            Spacer(minLength: 8)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                BetiFizzTheme.primaryGreen.opacity(0.35),
                                BetiFizzTheme.primaryGreen.opacity(0.08),
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
                        .frame(width: 132, height: 132)
                        .overlay {
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.35),
                                            BetiFizzTheme.primaryGreen.opacity(0.45),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.2
                                )
                        }
                    Image(systemName: symbol)
                        .font(.system(size: 52, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(BetiFizzTheme.primaryGreen)
                }
            }

            VStack(spacing: 14) {
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(BetiFizzTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Text(detail)
                    .font(.body)
                    .foregroundStyle(BetiFizzTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 28)
            }

            Spacer(minLength: 24)
        }
    }
}

#Preview {
    BetiFizzOnboardingView(onFinish: {})
}
