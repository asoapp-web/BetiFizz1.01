//
//  MatchDetailView.swift
//  BetiFizz
//

import SwiftUI

struct MatchDetailView: View {
    @State private var matchState: BetiFizzMatch
    @Binding var path: [MatchesRoute]

    init(match: BetiFizzMatch, path: Binding<[MatchesRoute]>) {
        _matchState = State(initialValue: match)
        _path = path
    }

    var body: some View {
        ZStack {
            LiquidGlassScreenBackground()
            ScrollView {
                VStack(spacing: 20) {
                    LiquidGlassCard {
                        VStack(spacing: 16) {
                            Text(matchState.leagueName)
                                .font(.caption)
                                .foregroundStyle(BetiFizzTheme.textSecondary)
                            HStack {
                                VStack(spacing: 8) {
                                    Text(matchState.homeTeamName)
                                        .font(.headline)
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(BetiFizzTheme.textPrimary)
                                    Text("\(matchState.homeScore ?? 0)")
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundStyle(BetiFizzTheme.textPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                Text("vs")
                                    .foregroundStyle(BetiFizzTheme.textSecondary)
                                VStack(spacing: 8) {
                                    Text(matchState.awayTeamName)
                                        .font(.headline)
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(BetiFizzTheme.textPrimary)
                                    Text("\(matchState.awayScore ?? 0)")
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundStyle(BetiFizzTheme.textPrimary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            if matchState.isLive, let t = matchState.time {
                                Text(t)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.red.opacity(0.9))
                            }
                            Text(matchState.date.betiFizzFormattedMatchLine())
                                .font(.caption)
                                .foregroundStyle(BetiFizzTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    VStack(spacing: 12) {
                        NavigationLink(value: MatchesRoute.team(matchState.homeTeamId)) {
                            HStack {
                                Text("Home: \(matchState.homeTeamName)")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(BetiFizzTheme.textSecondary)
                            }
                            .foregroundStyle(BetiFizzTheme.textPrimary)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .background {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.45)
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: MatchesRoute.team(matchState.awayTeamId)) {
                            HStack {
                                Text("Away: \(matchState.awayTeamName)")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(BetiFizzTheme.textSecondary)
                            }
                            .foregroundStyle(BetiFizzTheme.textPrimary)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .background {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.45)
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Match")
        .navigationBarTitleDisplayMode(.inline)
        .betiFizzNavigationChrome()
        .task(id: matchState.id) {
            await pollMatchDetailUpdates()
        }
    }

    /// Live: frequent refresh until final whistle. Upcoming: light polling so kickoff appears without reloading the whole day list. Finished: no requests.
    private func pollMatchDetailUpdates() async {
        guard !matchState.isFinished else { return }

        let fixtures = FixturesService.shared

        while !Task.isCancelled {
            if matchState.isFinished { return }

            do {
                if let m = try await fixtures.fetchMatch(id: matchState.id) {
                    await MainActor.run { matchState = m }
                    if m.isFinished { return }
                }
            } catch { /* offline / 429 */ }

            if Task.isCancelled { return }
            if matchState.isFinished { return }

            let nanos: UInt64
            if matchState.isLive {
                nanos = 45_000_000_000
            } else {
                let untilKickoff = matchState.date.timeIntervalSinceNow
                if untilKickoff > 90 * 60 {
                    nanos = 600_000_000_000
                } else if untilKickoff > 0 {
                    nanos = 180_000_000_000
                } else {
                    nanos = 60_000_000_000
                }
            }

            try? await Task.sleep(nanoseconds: nanos)
        }
    }
}
