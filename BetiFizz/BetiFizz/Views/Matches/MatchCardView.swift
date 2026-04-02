//
//  MatchCardView.swift
//  BetiFizz
//

import SwiftUI

struct MatchCardView: View {
    let match: BetiFizzMatch
    let isHomeFavorite: Bool
    let isAwayFavorite: Bool
    let onHomeFavorite: () -> Void
    let onAwayFavorite: () -> Void

    var body: some View {
        LiquidGlassCard {
            VStack(spacing: 14) {
                HStack(spacing: 5) {
                    Text(match.leagueFlag)
                        .font(.caption)
                    Text(match.leagueName)
                        .font(.caption)
                        .foregroundStyle(BetiFizzTheme.textSecondary)
                        .lineLimit(1)
                    Spacer()
                    if match.isLive {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red.opacity(0.9))
                                .frame(width: 7, height: 7)
                            Text("LIVE")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.red.opacity(0.95))
                        }
                    }
                }

                HStack(spacing: 16) {
                    teamSide(
                        name: match.homeTeamName,
                        logo: match.homeTeamLogoURL,
                        score: match.homeScore,
                        showTime: match.homeScore == nil,
                        isFavorite: isHomeFavorite,
                        onFav: onHomeFavorite
                    )
                    Text("vs")
                        .font(.caption)
                        .foregroundStyle(BetiFizzTheme.textSecondary)
                    teamSide(
                        name: match.awayTeamName,
                        logo: match.awayTeamLogoURL,
                        score: match.awayScore,
                        showTime: match.awayScore == nil,
                        isFavorite: isAwayFavorite,
                        onFav: onAwayFavorite
                    )
                }

                if match.isLive, let t = match.time {
                    Text(t)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.red.opacity(0.9))
                }

                Text(match.date.betiFizzFormattedMatchLine())
                    .font(.caption2)
                    .foregroundStyle(BetiFizzTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .overlay {
            if match.isLive {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.red.opacity(0.35), lineWidth: 1.5)
            }
        }
    }

    private func teamSide(
        name: String,
        logo: String?,
        score: Int?,
        showTime: Bool,
        isFavorite: Bool,
        onFav: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(BetiFizzTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
                Button(action: onFav) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundStyle(isFavorite ? Color.yellow.opacity(0.9) : BetiFizzTheme.textSecondary.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            crest(logo)
            if let s = score {
                Text("\(s)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(BetiFizzTheme.textPrimary)
                    .monospacedDigit()
            } else if showTime {
                Text(match.date.betiFizzTimeOnly())
                    .font(.caption)
                    .foregroundStyle(BetiFizzTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func crest(_ urlString: String?) -> some View {
        if let s = urlString, let u = URL(string: s) {
            AsyncImage(url: u) { phase in
                if let img = phase.image {
                    img.resizable().aspectRatio(contentMode: .fit)
                } else {
                    placeholderCrest
                }
            }
            .frame(width: 44, height: 44)
        } else {
            placeholderCrest
        }
    }

    private var placeholderCrest: some View {
        Circle()
            .fill(BetiFizzTheme.primaryGreen.opacity(0.2))
            .frame(width: 44, height: 44)
    }
}
