//
//  QuizTabView.swift
//  BetiFizz
//
//  Full-screen quiz experience launched from InteractiveTabView.
//  No tab bar visible while playing.
//

import CoreData
import SwiftUI

// MARK: - Full-screen wrapper

struct QuizFullScreenView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var phase: QuizPhase = .home
    @State private var statsSnapshot = QuizStatsSnapshot(attempted: 0, correct: 0, bestStreak: 0, currentStreak: 0, lastPlayedAt: nil)
    @State private var loadError: String?
    @State private var questionPool: [QuizQuestion] = []
    @State private var isLoadingBank = false

    var body: some View {
        ZStack {
            LiquidGlassScreenBackground()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 20) {
                        switch phase {
                        case .home:
                            homeContent
                        case .playing(let kind, let questions):
                            QuizPlayPanel(
                                questions: questions,
                                viewContext: viewContext,
                                onFinish: { correct in
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        phase = .finished(kind: kind, correct: correct, total: questions.count)
                                    }
                                    refreshStats()
                                }
                            )
                        case .finished(let kind, let correct, let total):
                            QuizCompletionView(
                                kind: kind,
                                correct: correct,
                                total: total,
                                onPlayAgain: { phase = .home; refreshStats() },
                                onExit: { dismiss() }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            QuizStatsRepository.bootstrapIfNeeded(context: viewContext)
            refreshStats()
        }
        .onReceive(NotificationCenter.default.publisher(for: .betiFizzQuizStatsDidChange)) { _ in
            refreshStats()
        }
        .task { await reloadBank() }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                HStack(spacing: 5) {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                    Text("Close")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(BetiFizzTheme.textSecondary)
            }
            Spacer()
            Text("Quiz")
                .font(.headline.weight(.bold))
                .foregroundStyle(BetiFizzTheme.textPrimary)
            Spacer()
            Color.clear.frame(width: 60, height: 1)
        }
    }

    private var homeContent: some View {
        VStack(spacing: 20) {
            if isLoadingBank {
                ProgressView("Loading question bank…")
                    .tint(BetiFizzTheme.primaryGreen)
                    .foregroundStyle(BetiFizzTheme.textSecondary)
            }

            if let loadError {
                LiquidGlassCard {
                    Text(loadError)
                        .font(.subheadline)
                        .foregroundStyle(BetiFizzTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            LiquidGlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Your stats", systemImage: "chart.bar.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(BetiFizzTheme.textPrimary)

                    statsRow("Questions answered", value: "\(statsSnapshot.attempted)")
                    statsRow("Correct", value: "\(statsSnapshot.correct)")
                    statsRow("Accuracy", value: statsSnapshot.accuracyText)
                    statsRow("Best streak", value: "\(statsSnapshot.bestStreak)")
                    statsRow("Current streak", value: "\(statsSnapshot.currentStreak)")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            LiquidGlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Daily challenge")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(BetiFizzTheme.textPrimary)
                    Text("Fixed sets per calendar day: Easy 10, Medium 20, Hard 30 questions.")
                        .font(.subheadline)
                        .foregroundStyle(BetiFizzTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text("Daily")
                .font(.caption.weight(.bold))
                .foregroundStyle(BetiFizzTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(QuizDifficulty.allCases) { diff in
                Button { startDaily(diff) } label: {
                    Text("Today — \(diff.title) (\(diff.questionCount))")
                }
                .buttonStyle(LiquidGlassPrimaryButtonStyle())
                .disabled(loadError != nil || questionPool.count < diff.questionCount)
                .opacity(questionPool.count < diff.questionCount ? 0.45 : 1)
            }

            Text("Practice")
                .font(.caption.weight(.bold))
                .foregroundStyle(BetiFizzTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)

            ForEach(QuizDifficulty.allCases) { diff in
                Button { startPractice(diff) } label: {
                    Text("Practice — \(diff.title) (\(diff.questionCount))")
                }
                .buttonStyle(LiquidGlassPrimaryButtonStyle())
                .disabled(loadError != nil || questionPool.count < diff.questionCount)
                .opacity(questionPool.count < diff.questionCount ? 0.45 : 1)
            }
        }
    }

    private func statsRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title).font(.subheadline).foregroundStyle(BetiFizzTheme.textSecondary)
            Spacer()
            Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(BetiFizzTheme.textPrimary)
        }
    }

    private func refreshStats() {
        statsSnapshot = QuizStatsRepository.snapshot(context: viewContext)
    }

    @MainActor
    private func reloadBank() async {
        isLoadingBank = true
        defer { isLoadingBank = false }
        do {
            let all = try QuizBankProvider.loadAllQuestions()
            questionPool = all
            loadError = nil
        } catch {
            loadError = "Could not load questions. Try reinstalling the app."
        }
    }

    private func startDaily(_ difficulty: QuizDifficulty) {
        let n = difficulty.questionCount
        let deck = QuizBankProvider.dailyChallenge(from: questionPool, count: n, daySalt: difficulty.dailySalt)
        guard deck.count >= n else {
            loadError = "Not enough questions in the bank for \(difficulty.title)."
            return
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            phase = .playing(.daily(difficulty), deck)
        }
    }

    private func startPractice(_ difficulty: QuizDifficulty) {
        let n = difficulty.questionCount
        let deck = QuizBankProvider.practiceRound(from: questionPool, count: n, practiceSalt: difficulty.practiceSalt)
        guard deck.count >= n else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            phase = .playing(.practice(difficulty), deck)
        }
    }
}

// MARK: - Session types

private enum QuizSessionKind: Equatable {
    case daily(QuizDifficulty)
    case practice(QuizDifficulty)

    var difficulty: QuizDifficulty {
        switch self { case .daily(let d), .practice(let d): return d }
    }
    var isDaily: Bool {
        if case .daily = self { return true }
        return false
    }
}

private enum QuizPhase: Equatable {
    case home
    case playing(QuizSessionKind, [QuizQuestion])
    case finished(kind: QuizSessionKind, correct: Int, total: Int)
}

// MARK: - Play panel

private struct QuizPlayPanel: View {
    let questions: [QuizQuestion]
    let viewContext: NSManagedObjectContext
    let onFinish: (Int) -> Void

    @State private var index = 0
    @State private var sessionCorrect = 0
    @State private var selectedIndex: Int?
    @State private var revealed = false

    private var current: QuizQuestion? {
        guard questions.indices.contains(index) else { return nil }
        return questions[index]
    }

    private var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(index + 1) / Double(questions.count)
    }

    var body: some View {
        VStack(spacing: 20) {
            ProgressView(value: progress)
                .tint(BetiFizzTheme.primaryGreen)
                .scaleEffect(y: 1.6)
                .padding(.bottom, 4)

            if let q = current {
                LiquidGlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Question \(index + 1) of \(questions.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(BetiFizzTheme.primaryGreen)
                        Text(q.question)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(BetiFizzTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(spacing: 12) {
                    ForEach(Array(q.options.enumerated()), id: \.offset) { offset, option in
                        Button { pickOption(offset, for: q) } label: {
                            Text(option)
                        }
                        .buttonStyle(
                            LiquidGlassOptionButtonStyle(
                                isSelected: selectedIndex == offset,
                                isRevealed: revealed,
                                isCorrectOption: offset == q.correctIndex
                            )
                        )
                        .disabled(revealed)
                    }
                }

                if revealed {
                    Button {
                        advance()
                    } label: {
                        Text(index >= questions.count - 1 ? "See results" : "Next question")
                    }
                    .buttonStyle(LiquidGlassPrimaryButtonStyle())
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: revealed)
    }

    private func pickOption(_ offset: Int, for q: QuizQuestion) {
        guard !revealed else { return }
        selectedIndex = offset
        revealed = true
        let correct = offset == q.correctIndex
        if correct { sessionCorrect += 1 }
        QuizStatsRepository.recordAnswer(isCorrect: correct, context: viewContext)
    }

    private func advance() {
        if index >= questions.count - 1 {
            onFinish(sessionCorrect)
            return
        }
        index += 1
        selectedIndex = nil
        revealed = false
    }
}

// MARK: - Completion screen

private struct QuizCompletionView: View {
    let kind: QuizSessionKind
    let correct: Int
    let total: Int
    let onPlayAgain: () -> Void
    let onExit: () -> Void

    @State private var animateScore = false
    @State private var showConfetti = false
    @State private var confettiPieces: [ConfettiPiece] = []

    private var percentage: Int {
        guard total > 0 else { return 0 }
        return Int(round(Double(correct) / Double(total) * 100))
    }

    private var emoji: String {
        switch percentage {
        case 90...100: return "🏆"
        case 70..<90:  return "🌟"
        case 50..<70:  return "👏"
        default:       return "💪"
        }
    }

    private var headline: String {
        switch percentage {
        case 90...100: return "Outstanding!"
        case 70..<90:  return "Great job!"
        case 50..<70:  return "Not bad!"
        default:       return "Keep practicing!"
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer(minLength: 16)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    scoreColor.opacity(0.4),
                                    scoreColor.opacity(0.08),
                                    Color.clear,
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 140
                            )
                        )
                        .frame(width: 260, height: 260)
                        .blur(radius: 2)

                    VStack(spacing: 10) {
                        Text(emoji)
                            .font(.system(size: 62))
                            .scaleEffect(animateScore ? 1.0 : 0.3)
                            .opacity(animateScore ? 1 : 0)

                        Text("\(percentage)%")
                            .font(.system(size: 56, weight: .heavy, design: .rounded))
                            .foregroundStyle(scoreColor)
                            .scaleEffect(animateScore ? 1.0 : 0.5)
                            .opacity(animateScore ? 1 : 0)

                        Text("\(correct) / \(total) correct")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(BetiFizzTheme.textSecondary)
                            .opacity(animateScore ? 1 : 0)
                    }
                }

                Spacer(minLength: 12)

                VStack(spacing: 8) {
                    Text(headline)
                        .font(.title.weight(.bold))
                        .foregroundStyle(BetiFizzTheme.textPrimary)
                        .opacity(animateScore ? 1 : 0)

                    Text(kind.isDaily ? "Daily \(kind.difficulty.title)" : "Practice \(kind.difficulty.title)")
                        .font(.subheadline)
                        .foregroundStyle(BetiFizzTheme.textSecondary)
                        .opacity(animateScore ? 1 : 0)
                }

                Spacer(minLength: 24)

                VStack(spacing: 14) {
                    Button { onPlayAgain() } label: {
                        Text("Play again")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LiquidGlassPrimaryButtonStyle())

                    Button { onExit() } label: {
                        Text("Done")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(BetiFizzTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
                .opacity(animateScore ? 1 : 0)
            }

            if showConfetti {
                ConfettiOverlay(pieces: confettiPieces)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            confettiPieces = (0..<80).map { _ in ConfettiPiece() }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.15)) {
                animateScore = true
            }
            withAnimation(.easeOut(duration: 0.2).delay(0.1)) {
                showConfetti = true
            }
        }
    }

    private var scoreColor: Color {
        switch percentage {
        case 80...100: return BetiFizzTheme.primaryGreen
        case 50..<80:  return Color.orange
        default:       return Color(red: 1, green: 0.35, blue: 0.35)
        }
    }
}

// MARK: - Confetti

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let x: CGFloat = CGFloat.random(in: 0...1)
    let size: CGFloat = CGFloat.random(in: 5...10)
    let color: Color = [
        Color(red: 34/255, green: 197/255, blue: 94/255),
        Color.yellow,
        Color.orange,
        Color.cyan,
        Color.pink,
        Color.purple,
        Color.white,
    ].randomElement()!
    let rotation: Double = Double.random(in: 0...360)
    let delay: Double = Double.random(in: 0...0.6)
    let duration: Double = Double.random(in: 1.8...3.0)
}

private struct ConfettiOverlay: View {
    let pieces: [ConfettiPiece]
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ForEach(pieces) { p in
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(p.color)
                    .frame(width: p.size, height: p.size * CGFloat.random(in: 1.5...3))
                    .rotationEffect(.degrees(animate ? p.rotation + 360 : p.rotation))
                    .position(
                        x: geo.size.width * p.x,
                        y: animate ? geo.size.height + 40 : -20
                    )
                    .opacity(animate ? 0 : 1)
                    .animation(
                        .easeIn(duration: p.duration).delay(p.delay),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

#Preview {
    QuizFullScreenView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
