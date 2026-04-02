//
//  MatchesHomeView.swift
//  BetiFizz
//

import CoreData
import SwiftUI

enum MatchesRoute: Hashable {
    case match(BetiFizzMatch)
    case team(String)
}

struct MatchesHomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var matchesVM = MatchesListViewModel.shared
    @StateObject private var teamsVM   = TeamsListViewModel.shared

    @State private var segment = 0
    @State private var path: [MatchesRoute] = []
    @State private var showLeaguePicker = false
    @State private var showDateRangeSheet = false

    private var localTodayKey: TimeInterval {
        Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                LiquidGlassScreenBackground()

                VStack(spacing: 0) {
                    GlassSegmentedControl(selection: $segment, options: ["Matches", "Teams"])
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    if segment == 0 {
                        matchesTab
                    } else {
                        teamsTab
                    }
                }
            }
            .navigationTitle("Matches")
            .betiFizzNavigationChrome()
            .navigationDestination(for: MatchesRoute.self) { route in
                switch route {
                case .match(let m):
                    MatchDetailView(match: m, path: $path)
                case .team(let id):
                    TeamDetailView(teamId: id)
                }
            }
        }
        .task(id: localTodayKey) {
            await matchesVM.loadMatches()
        }
        .task(id: segment) {
            guard segment == 0 else { return }
            await matchesVM.pollLiveMatchesWhileVisible()
        }
        .sheet(isPresented: $showLeaguePicker) {
            LeaguePickerSheet(
                leagues: matchesVM.availableLeagues,
                initialSelection: matchesVM.selectedLeagueIds,
                onApply: { new in
                    Task { await matchesVM.applyLeagueSelection(new) }
                }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showDateRangeSheet) {
            MatchFetchRangeSheet(initial: matchesVM.fetchRange) { new in
                Task { await matchesVM.applyFetchRange(new) }
            }
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Matches tab

    private var matchesTab: some View {
        VStack(spacing: 0) {
            filterBar

            if matchesVM.isLoading, matchesVM.matches.isEmpty {
                Spacer()
                ProgressView().tint(BetiFizzTheme.primaryGreen)
                Spacer()
            } else if let err = matchesVM.errorMessage, matchesVM.matches.isEmpty {
                ScrollView {
                    emptyCard(
                        title: "Couldn’t load matches",
                        message: err,
                        button: "Retry",
                        action: { Task { await matchesVM.refresh() } }
                    )
                    .padding(20)
                }
            } else if matchesVM.filteredMatches.isEmpty {
                ScrollView {
                    emptyCard(
                        title: "No matches",
                        message: matchesVM.matchFilter == .today
                            ? "No fixtures today in the loaded window. Try All, change dates, or leagues."
                            : "No fixtures in this range. Change dates or leagues, or pull to refresh.",
                        button: "Refresh",
                        action: { Task { await matchesVM.refresh() } }
                    )
                    .padding(20)
                }
                .refreshable { await matchesVM.refresh() }
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(matchesVM.filteredMatches) { m in
                            NavigationLink(value: MatchesRoute.match(m)) {
                                MatchCardView(
                                    match: m,
                                    isHomeFavorite: matchesVM.isFavorite(teamId: m.homeTeamId, context: viewContext),
                                    isAwayFavorite: matchesVM.isFavorite(teamId: m.awayTeamId, context: viewContext),
                                    onHomeFavorite: {
                                        matchesVM.toggleFavorite(teamId: m.homeTeamId, name: m.homeTeamName, crest: m.homeTeamLogoURL, context: viewContext)
                                    },
                                    onAwayFavorite: {
                                        matchesVM.toggleFavorite(teamId: m.awayTeamId, name: m.awayTeamName, crest: m.awayTeamLogoURL, context: viewContext)
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
                .refreshable { await matchesVM.refresh() }
            }
        }
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach([BetiFizzMatchDateFilter.all, .today], id: \.rawValue) { f in
                    filterChip(f.shortTitle, selected: matchesVM.matchFilter == f) {
                        matchesVM.matchFilter = f
                    }
                }

                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1, height: 22)
                    .padding(.horizontal, 2)

                dateRangeChip

                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1, height: 22)
                    .padding(.horizontal, 2)

                leagueChip
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }

    private var dateRangeChip: some View {
        Button { showDateRangeSheet = true } label: {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption.weight(.semibold))
                Text(matchesVM.fetchRangeShortLabel)
                    .lineLimit(1)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(BetiFizzTheme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(Color.white.opacity(0.08))
            }
            .overlay { Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1) }
        }
        .buttonStyle(.plain)
    }

    private var leagueChip: some View {
        Button { showLeaguePicker = true } label: {
            HStack(spacing: 5) {
                if matchesVM.selectedLeagueIds.isEmpty {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text("Leagues")
                } else if matchesVM.selectedLeagueIds.count == 1,
                          let only = matchesVM.selectedLeagueIds.first,
                          let league = matchesVM.availableLeagues.first(where: { $0.id == only }) {
                    Text(league.flag)
                    Text(league.name)
                        .lineLimit(1)
                } else {
                    Image(systemName: "sportscourt.fill")
                    Text("\(matchesVM.selectedLeagueIds.count) leagues")
                        .lineLimit(1)
                }
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(matchesVM.selectedLeagueIds.isEmpty ? BetiFizzTheme.textSecondary : BetiFizzTheme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(matchesVM.selectedLeagueIds.isEmpty ? Color.white.opacity(0.06) : BetiFizzTheme.primaryGreen.opacity(0.35))
            }
            .overlay { Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1) }
        }
        .buttonStyle(.plain)
    }

    private func filterChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(selected ? BetiFizzTheme.textPrimary : BetiFizzTheme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(selected
                              ? BetiFizzTheme.primaryGreen.opacity(0.35)
                              : Color.white.opacity(0.06))
                }
                .overlay { Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1) }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Teams tab

    private var teamsTab: some View {
        Group {
            if teamsVM.isLoading, teamsVM.teams.isEmpty {
                Spacer()
                ProgressView().tint(BetiFizzTheme.primaryGreen)
                Spacer()
            } else if let err = teamsVM.errorMessage, teamsVM.teams.isEmpty {
                ScrollView {
                    emptyCard(title: "Couldn’t load teams", message: err, button: "Retry") {
                        Task { await teamsVM.loadTeams() }
                    }
                    .padding(20)
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(BetiFizzTheme.textSecondary)
                            TextField("Search teams", text: $teamsVM.searchText)
                                .foregroundStyle(BetiFizzTheme.textPrimary)
                                .tint(BetiFizzTheme.primaryGreen)
                        }
                        .padding(12)
                        .background(.ultraThinMaterial.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        }

                        ForEach(teamsVM.teamsByDivision, id: \.division) { group in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(group.division.uppercased())
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(BetiFizzTheme.primaryGreen)
                                    .tracking(1.1)
                                ForEach(group.teams) { team in
                                    NavigationLink(value: MatchesRoute.team(team.id)) {
                                        TeamRowGlassCard(
                                            team: team,
                                            isFavorite: teamsVM.isFavorite(teamId: team.id, context: viewContext),
                                            onFavorite: { teamsVM.toggleFavorite(team: team, context: viewContext) }
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
                .refreshable { await teamsVM.loadTeams() }
            }
        }
        .task {
            await teamsVM.loadTeams()
        }
    }

    private func emptyCard(title: String, message: String, button: String, action: @escaping () -> Void) -> some View {
        LiquidGlassCard {
            VStack(spacing: 14) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(BetiFizzTheme.textPrimary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(BetiFizzTheme.textSecondary)
                    .multilineTextAlignment(.center)
                Button(action: action) { Text(button) }
                    .buttonStyle(LiquidGlassPrimaryButtonStyle())
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Fetch date range (≤10 days — API limit)

private enum FetchRangePickMode: Int, CaseIterable {
    case rolling
    case fixedRange
    case singleDay
}

private struct MatchFetchRangeSheet: View {
    let initial: BetiFizzMatchFetchRange
    let onApply: (BetiFizzMatchFetchRange) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var mode: FetchRangePickMode = .rolling
    @State private var rollingDays = 10
    @State private var fromDate = Date()
    @State private var toDate = Date()
    @State private var singleDate = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassScreenBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Picker("Mode", selection: $mode) {
                            Text("Next days").tag(FetchRangePickMode.rolling)
                            Text("Range").tag(FetchRangePickMode.fixedRange)
                            Text("One day").tag(FetchRangePickMode.singleDay)
                        }
                        .pickerStyle(.segmented)

                        Group {
                            switch mode {
                            case .rolling: rollingBlock
                            case .fixedRange: rangeBlock
                            case .singleDay: singleBlock
                            }
                        }

                        Text("football-data.org free tier: at most 10 calendar days per request.")
                            .font(.caption)
                            .foregroundStyle(BetiFizzTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Match dates")
            .navigationBarTitleDisplayMode(.inline)
            .betiFizzNavigationChrome()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(BetiFizzTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        guard let r = buildAppliedRange(), r.isValid() else { return }
                        onApply(r)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(BetiFizzTheme.primaryGreen)
                    .disabled(!applyEnabled)
                }
            }
            .onAppear(perform: hydrateFromInitial)
        }
    }

    private var rollingBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Starting today, load the next \(rollingDays) day(s) (inclusive).")
                .font(.subheadline)
                .foregroundStyle(BetiFizzTheme.textSecondary)
            Stepper("Days: \(rollingDays)", value: $rollingDays, in: 1...10)
                .foregroundStyle(BetiFizzTheme.textPrimary)
        }
    }

    private var rangeBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("From")
                .font(.caption.weight(.semibold))
                .foregroundStyle(BetiFizzTheme.textSecondary)
            DatePicker("", selection: $fromDate, displayedComponents: .date)
                .labelsHidden()
                .tint(BetiFizzTheme.primaryGreen)
            Text("To")
                .font(.caption.weight(.semibold))
                .foregroundStyle(BetiFizzTheme.textSecondary)
            DatePicker("", selection: $toDate, displayedComponents: .date)
                .labelsHidden()
                .tint(BetiFizzTheme.primaryGreen)
            Text(rangeSpanCaption)
                .font(.caption)
                .foregroundStyle(rangeIsValid ? BetiFizzTheme.textSecondary : Color.orange)
        }
    }

    private var singleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Load fixtures for one calendar day.")
                .font(.subheadline)
                .foregroundStyle(BetiFizzTheme.textSecondary)
            DatePicker("Date", selection: $singleDate, displayedComponents: .date)
                .tint(BetiFizzTheme.primaryGreen)
        }
    }

    private var rangeSpanCaption: String {
        let cal = Calendar.current
        let f = cal.startOfDay(for: fromDate)
        let t = cal.startOfDay(for: toDate)
        let lo = min(f, t)
        let hi = max(f, t)
        let span = BetiFizzMatchFetchRange.inclusiveDayCount(from: lo, to: hi, cal: cal)
        return "\(span) day(s) selected (maximum 10)."
    }

    private var rangeIsValid: Bool {
        let cal = Calendar.current
        let f = cal.startOfDay(for: fromDate)
        let t = cal.startOfDay(for: toDate)
        return BetiFizzMatchFetchRange.inclusiveDayCount(from: min(f, t), to: max(f, t), cal: cal) <= 10
    }

    private var applyEnabled: Bool {
        switch mode {
        case .rolling, .singleDay: return true
        case .fixedRange: return rangeIsValid
        }
    }

    private func hydrateFromInitial() {
        switch initial.mode {
        case .rollingNextDays:
            mode = .rolling
            rollingDays = min(10, max(1, initial.rollingDays))
        case .customRange:
            mode = .fixedRange
            if let ts = initial.rangeStart { fromDate = Date(timeIntervalSince1970: ts) }
            if let te = initial.rangeEnd { toDate = Date(timeIntervalSince1970: te) }
        case .singleDay:
            mode = .singleDay
            if let ts = initial.rangeStart { singleDate = Date(timeIntervalSince1970: ts) }
        }
    }

    private func buildAppliedRange() -> BetiFizzMatchFetchRange? {
        let cal = Calendar.current
        switch mode {
        case .rolling:
            return BetiFizzMatchFetchRange(
                mode: .rollingNextDays,
                rollingDays: rollingDays,
                rangeStart: nil,
                rangeEnd: nil
            )
        case .fixedRange:
            var f = cal.startOfDay(for: fromDate)
            var t = cal.startOfDay(for: toDate)
            if f > t { swap(&f, &t) }
            let span = BetiFizzMatchFetchRange.inclusiveDayCount(from: f, to: t, cal: cal)
            guard span <= BetiFizzMatchFetchRange.apiMaxInclusiveDays else { return nil }
            return BetiFizzMatchFetchRange(
                mode: .customRange,
                rollingDays: 10,
                rangeStart: f.timeIntervalSince1970,
                rangeEnd: t.timeIntervalSince1970
            )
        case .singleDay:
            let d = cal.startOfDay(for: singleDate)
            return BetiFizzMatchFetchRange(
                mode: .singleDay,
                rollingDays: 10,
                rangeStart: d.timeIntervalSince1970,
                rangeEnd: nil
            )
        }
    }
}

// MARK: - League picker (multi-select + Apply)

private struct LeaguePickerSheet: View {
    let leagues: [BetiFizzLeagueOption]
    let initialSelection: Set<String>
    let onApply: (Set<String>) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: Set<String> = []

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassScreenBackground()
                ScrollView {
                    VStack(spacing: 10) {
                        Button {
                            draft.removeAll()
                        } label: {
                            leagueRow(flag: "⚽️", name: "All leagues", isSelected: draft.isEmpty)
                        }
                        .buttonStyle(.plain)

                        ForEach(leagues) { league in
                            Button {
                                if draft.contains(league.id) {
                                    draft.remove(league.id)
                                } else {
                                    draft.insert(league.id)
                                }
                            } label: {
                                leagueRow(
                                    flag: league.flag,
                                    name: league.name,
                                    isSelected: draft.contains(league.id)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Leagues")
            .navigationBarTitleDisplayMode(.inline)
            .betiFizzNavigationChrome()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(BetiFizzTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(BetiFizzTheme.primaryGreen)
                }
            }
            .onAppear { draft = initialSelection }
        }
    }

    private func leagueRow(flag: String, name: String, isSelected: Bool) -> some View {
        LiquidGlassCard(cornerRadius: 16, highlightOpacity: 0.28) {
            HStack(spacing: 12) {
                Text(flag).font(.title3)
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(BetiFizzTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(BetiFizzTheme.primaryGreen)
                }
            }
        }
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(BetiFizzTheme.primaryGreen.opacity(0.5), lineWidth: 1.5)
            }
        }
    }
}
