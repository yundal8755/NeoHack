import HackertonCore
import Kingfisher
import SwiftUI

@main
struct HackertonBoilerplateApp: App {
    init() {
        AppLogger.configure()
        configureImageCache()
    }

    private func configureImageCache() {
        ImageCache.default.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024
        ImageCache.default.memoryStorage.config.countLimit = 120
    }

    var body: some Scene {
        WindowGroup {
            SplashContainer(showsSplash: AppContainer.shared.configuration.showsSplash) {
                OnboardingContainer(isEnabled: AppContainer.shared.configuration.showsOnboarding) {
                    RootView()
                }
            }
        }
    }
}
