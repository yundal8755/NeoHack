import Foundation

final class AppContainer {
    static let shared = AppContainer()

    let tokenStore: TokenStoring
    let networkManager: NetworkManager
    let authRepository: any AuthRepositoryProtocol
    let userRepository: any UserRepositoryProtocol
    let ticketRepository: any TicketRepositoryProtocol
    let likeRepository: any LikeRepositoryProtocol
    let movieRepository: MovieRepositoryProtocol

    init(
        tokenStore: TokenStoring = KeychainTokenStore()
    ) {
        AppLogger.debug("Initializing app container")
        self.tokenStore = tokenStore
        self.networkManager = NetworkManager(authInterceptor: AuthInterceptor(tokenStore: tokenStore))
        self.authRepository = AuthRepository(networkManager: networkManager, tokenStore: tokenStore)
        self.userRepository = UserRepository(networkManager: networkManager, tokenStore: tokenStore)
        self.ticketRepository = TicketRepository(networkManager: networkManager, tokenStore: tokenStore)
        self.likeRepository = LikeRepository(networkManager: networkManager, tokenStore: tokenStore)
        self.movieRepository = MovieRepository(networkManager: networkManager, tokenStore: tokenStore)
        AppLogger.debug("App container initialized")
    }
}
