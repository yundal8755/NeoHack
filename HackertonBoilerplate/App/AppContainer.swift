import Foundation
import HackertonCore
import HackertonMocks

final class AppContainer {
    static let shared = AppContainer()

    let configuration: AppLaunchConfiguration
    let tokenStore: TokenStoring
    let networkManager: NetworkManager

    /// 실행 인자에 `-mock-mode`가 있으면 Mock 구현체를 주입한다. UI 테스트가 네트워크 없이 돌 때 사용한다.
    init(configuration: AppLaunchConfiguration = .current) {
        AppLogger.debug("Initializing app container: \(configuration.dataMode)")
        self.configuration = configuration

        let tokenStore: TokenStoring = switch configuration.dataMode {
        case .live: KeychainTokenStore()
        case .mock: InMemoryTokenStore()
        }

        self.tokenStore = tokenStore
        self.networkManager = NetworkManager(authInterceptor: AuthInterceptor(tokenStore: tokenStore))
        AppLogger.debug("App container initialized")
    }
}
