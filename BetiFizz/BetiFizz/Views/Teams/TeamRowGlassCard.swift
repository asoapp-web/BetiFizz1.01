//
//  TeamRowGlassCard.swift
//  BetiFizz
//

import SwiftUI

struct TeamRowGlassCard: View {
    let team: Team
    let isFavorite: Bool
    let onFavorite: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            crest
            VStack(alignment: .leading, spacing: 4) {
                Text(team.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(BetiFizzTheme.textPrimary)
                if let city = team.city {
                    Text(city)
                        .font(.caption)
                        .foregroundStyle(BetiFizzTheme.textSecondary)
                }
            }
            Spacer()
            Button(action: onFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? Color.yellow.opacity(0.9) : BetiFizzTheme.textSecondary)
            }
            .buttonStyle(.plain)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(BetiFizzTheme.textSecondary)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.45)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), BetiFizzTheme.primaryGreen.opacity(0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    @ViewBuilder
    private var crest: some View {
        if let s = team.logoURL, let u = URL(string: s) {
            AsyncImage(url: u) { phase in
                if let img = phase.image {
                    img.resizable().aspectRatio(contentMode: .fit)
                } else {
                    Circle().fill(BetiFizzTheme.primaryGreen.opacity(0.2))
                }
            }
            .frame(width: 44, height: 44)
        } else {
            Circle()
                .fill(BetiFizzTheme.primaryGreen.opacity(0.2))
                .frame(width: 44, height: 44)
        }
    }
}
