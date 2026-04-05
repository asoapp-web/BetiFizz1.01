//
//  SettingsView.swift
//  BetiFizz
//

import CoreData
import SwiftUI

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("BetiFizz.hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var confirmReset = false

    var body: some View {
        ZStack {
            LiquidGlassScreenBackground()

            List {
                Section {
                    Button(role: .destructive) {
                        confirmReset = true
                    } label: {
                        HStack {
                            Text("Reset quiz statistics")
                            Spacer()
                        }
                    }
                } header: {
                    Text("Quiz")
                } footer: {
                    Text("Clears your local score, streaks, and answer counts. Favorites are not removed.")
                }

                Section {
                    Button {
                        hasCompletedOnboarding = false
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .foregroundStyle(BetiFizzTheme.primaryGreen)
                            Text("Restart onboarding")
                                .foregroundStyle(BetiFizzTheme.textPrimary)
                            Spacer()
                        }
                    }
                } footer: {
                    Text("Show the welcome screens again on next launch.")
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .betiFizzNavigationChrome()
        .confirmationDialog(
            "Reset all quiz statistics?",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                QuizStatsRepository.resetAll(context: viewContext)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
