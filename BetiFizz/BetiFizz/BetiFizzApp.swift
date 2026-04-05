import SwiftUI
import CoreData

@main
struct BetiFizzApp: App {
    let persistence = PersistenceController.shared

    @AppStorage("BetiFizz.hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        Self.migrateOnboardingForExistingInstalls()
        configureAppearance()
    }

    /// First launch after adding onboarding: skip the flow if caches show the app was already used.
    private static func migrateOnboardingForExistingInstalls() {
        let defs = UserDefaults.standard
        let key = "BetiFizz.hasCompletedOnboarding"
        guard defs.object(forKey: key) == nil else { return }
        let hadPriorData =
            defs.data(forKey: BetiFizzUserDefaultsKeys.matchesCache) != nil
            || defs.data(forKey: BetiFizzUserDefaultsKeys.teamsCache) != nil
        if hadPriorData {
            defs.set(true, forKey: key)
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                } else {
                    BetiFizzOnboardingView {
                        hasCompletedOnboarding = true
                    }
                }
            }
            .environment(\.managedObjectContext, persistence.container.viewContext)
            .preferredColorScheme(.dark)
        }
    }

    private func configureAppearance() {
        let bg = UIColor(red: 13/255, green: 17/255, blue: 23/255, alpha: 0.96)
        let green = UIColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1)
        let gray = UIColor.systemGray2

        let page = UIPageControl.appearance()
        page.currentPageIndicatorTintColor = green
        page.pageIndicatorTintColor = gray.withAlphaComponent(0.35)

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = bg
        tab.stackedLayoutAppearance.normal.iconColor = gray
        tab.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: gray]
        tab.stackedLayoutAppearance.selected.iconColor = green
        tab.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: green]
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = bg
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().tintColor = green
    }
}
