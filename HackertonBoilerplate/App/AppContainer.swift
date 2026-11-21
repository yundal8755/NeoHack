import Foundation

final class AppContainer {
    static let shared = AppContainer()

    let tokenStore: TokenStoring
    let networkManager: NetworkManager

    init(
        tokenStore: TokenStoring = KeychainTokenStore()
    ) {
        AppLogger.debug("Initializing app container")
        self.tokenStore = tokenStore
        self.networkManager = NetworkManager(authInterceptor: AuthInterceptor(tokenStore: tokenStore))
        AppLogger.debug("App container initialized")
    }
}
