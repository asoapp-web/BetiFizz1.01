//
//  TeamDetailView.swift
//  BetiFizz
//

import CoreData
import SwiftUI

struct TeamDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let teamId: String
    @StateObject private var vm = TeamDetailViewModel()

    var body: some View {
        ZStack {
            LiquidGlassScreenBackground()

            if vm.isLoading, vm.team == nil {
                ProgressView().tint(BetiFizzTheme.primaryGreen)
            } else if let t = vm.team {
                ScrollView {
                    VStack(spacing: 18) {
                        LiquidGlassCard {
                            VStack(spacing: 14) {
                                crest(t.logoURL)
                                Text(t.fullName)
                                    .font(.title2.weight(.bold))
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(BetiFizzTheme.textPrimary)
                                if let city = t.city {
                                    Label(city, systemImage: "mappin.circle.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(BetiFizzTheme.textSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }

                        if !vm.squad.isEmpty {
                            LiquidGlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Squad")
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(BetiFizzTheme.textPrimary)
                                    ForEach(vm.squad.prefix(40)) { p in
                                        HStack {
                                            if let n = p.shirtNumber {
                                                Text("#\(n)")
                                                    .font(.caption.monospacedDigit())
                                                    .foregroundStyle(BetiFizzTheme.primaryGreen)
                                                    .frame(width: 36, alignment: .leading)
                                            }
                                            Text(p.name)
                                                .font(.subheadline)
                                                .foregroundStyle(BetiFizzTheme.textPrimary)
                                            Spacer()
                                            if let pos = p.position {
                                                Text(pos)
                                                    .font(.caption2)
                                                    .foregroundStyle(BetiFizzTheme.textSecondary)
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 32)
                }
            } else {
                Text(vm.errorMessage ?? "Team not found")
                    .foregroundStyle(BetiFizzTheme.textSecondary)
                    .padding()
            }
        }
        .navigationTitle(vm.team?.name ?? "Team")
        .navigationBarTitleDisplayMode(.inline)
        .betiFizzNavigationChrome()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    vm.toggleFavorite(context: viewContext)
                } label: {
                    Image(systemName: vm.isFavorite(context: viewContext, teamId: teamId) ? "star.fill" : "star")
                        .foregroundStyle(vm.isFavorite(context: viewContext, teamId: teamId) ? Color.yellow : BetiFizzTheme.textSecondary)
                }
                .id(vm.stateVersion)
            }
        }
        .task {
            await vm.load(teamId: teamId)
        }
        .onReceive(NotificationCenter.default.publisher(for: .betiFizzFavoritesDidChange)) { _ in
            vm.stateVersion += 1
        }
    }

    @ViewBuilder
    private func crest(_ urlString: String?) -> some View {
        if let s = urlString, let u = URL(string: s) {
            AsyncImage(url: u) { phase in
                if let img = phase.image {
                    img.resizable().aspectRatio(contentMode: .fit)
                } else {
                    Circle().fill(BetiFizzTheme.primaryGreen.opacity(0.2)).frame(width: 100, height: 100)
                }
            }
            .frame(width: 100, height: 100)
        } else {
            Circle()
                .fill(BetiFizzTheme.primaryGreen.opacity(0.2))
                .frame(width: 100, height: 100)
        }
    }
}
