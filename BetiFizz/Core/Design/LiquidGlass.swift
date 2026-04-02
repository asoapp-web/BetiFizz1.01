//
//  LiquidGlass.swift
//  BetiFizz
//

import SwiftUI

// MARK: - Screen backdrop

struct LiquidGlassScreenBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    BetiFizzTheme.background,
                    BetiFizzTheme.backgroundCard.opacity(0.94),
                    BetiFizzTheme.background.opacity(0.98),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Soft green bloom (liquid depth)
            RadialGradient(
                colors: [
                    BetiFizzTheme.primaryGreen.opacity(0.14),
                    Color.clear,
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 320
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    BetiFizzTheme.darkGreen.opacity(0.12),
                    Color.clear,
                ],
                center: .bottomLeading,
                startRadius: 10,
                endRadius: 280
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Card

struct LiquidGlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 22
    var highlightOpacity: Double = 0.42
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(18)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.5)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.02),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.26),
                                BetiFizzTheme.primaryGreen.opacity(0.35),
                                Color.white.opacity(0.1),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.25
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(0.35), lineWidth: 0.5)
                    .blur(radius: 0.5)
                    .offset(y: 1)
                    .mask(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(highlightOpacity),
                                Color.white.opacity(0.06),
                                Color.clear,
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(height: 88)
                    .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.4), radius: 18, y: 10)
    }
}

// MARK: - Primary pill button

struct LiquidGlassPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(BetiFizzTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    BetiFizzTheme.primaryGreen,
                                    BetiFizzTheme.darkGreen,
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.25)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            }
            .shadow(color: BetiFizzTheme.primaryGreen.opacity(0.35), radius: configuration.isPressed ? 4 : 12, y: configuration.isPressed ? 2 : 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

// MARK: - Secondary option chip (quiz answers)

struct LiquidGlassOptionButtonStyle: ButtonStyle {
    var isSelected: Bool
    var isRevealed: Bool
    var isCorrectOption: Bool

    func makeBody(configuration: Configuration) -> some View {
        let borderGreen = isRevealed && isCorrectOption
        let borderRed = isRevealed && isSelected && !isCorrectOption

        return configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(BetiFizzTheme.textPrimary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.thinMaterial)
                        .opacity(isSelected ? 0.65 : 0.45)

                    if borderGreen {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(BetiFizzTheme.primaryGreen.opacity(0.22))
                    }
                    if borderRed {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.red.opacity(0.18))
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: borderGreen
                                ? [BetiFizzTheme.primaryGreen.opacity(0.9), BetiFizzTheme.darkGreen.opacity(0.6)]
                                : borderRed
                                    ? [Color.red.opacity(0.7), Color.red.opacity(0.35)]
                                    : [
                                        Color.white.opacity(isSelected ? 0.35 : 0.18),
                                        BetiFizzTheme.primaryGreen.opacity(isSelected ? 0.28 : 0.12),
                                    ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: borderGreen || borderRed ? 2 : 1.1
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

// MARK: - Glass segmented control

struct GlassSegmentedControl: View {
    @Binding var selection: Int
    let options: [String]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(options.indices, id: \.self) { idx in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                        selection = idx
                    }
                } label: {
                    Text(options[idx])
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selection == idx ? Color.white : BetiFizzTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background {
                            if selection == idx {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [BetiFizzTheme.primaryGreen, BetiFizzTheme.darkGreen],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: BetiFizzTheme.primaryGreen.opacity(0.4), radius: 6, y: 3)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
    }
}

// MARK: - Navigation chrome

extension View {
    func betiFizzNavigationChrome() -> some View {
        toolbarBackground(BetiFizzTheme.background.opacity(0.88), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
