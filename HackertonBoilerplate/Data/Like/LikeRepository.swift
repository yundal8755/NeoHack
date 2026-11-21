import Foundation

protocol LikeRepositoryProtocol {
    var hasAccessToken: Bool { get }
    func addLike(ticketId: Int64) async throws(NetworkError)
    func removeLike(ticketId: Int64) async throws(NetworkError)
    func signOut()
}

final class LikeRepository: LikeRepositoryProtocol {
    private let networkManager: NetworkManager
    private let tokenStore: TokenStoring

    init(networkManager: NetworkManager, tokenStore: TokenStoring) {
        self.networkManager = networkManager
        self.tokenStore = tokenStore
    }

    var hasAccessToken: Bool {
        tokenStore.accessToken?.isEmpty == false
    }

    func addLike(ticketId: Int64) async throws(NetworkError) {
        try await requestVoid(
            LikeEndpoint.add(ticketId: ticketId),
            failureCode: "LIKE_ADD_FAILED",
            idempotency: .alreadyAdded
        )
    }

    func removeLike(ticketId: Int64) async throws(NetworkError) {
        try await requestVoid(
            LikeEndpoint.remove(ticketId: ticketId),
            failureCode: "LIKE_REMOVE_FAILED",
            idempotency: .alreadyRemoved
        )
    }

    func signOut() {
        tokenStore.clear()
    }

    private func requestVoid(
        _ endpoint: LikeEndpoint,
        failureCode: String,
        idempotency: LikeIdempotency
    ) async throws(NetworkError) {
        let response: LikeAPIResponseDTO<String>
        do {
            response = try await networkManager.request(
                endpoint,
                as: LikeAPIResponseDTO<String>.self
            )
        } catch {
            let networkError = Self.networkError(from: error)
            guard idempotency.treatsAsSuccess(networkError) else {
                throw networkError
            }
            AppLogger.info("Like request treated as idempotent success: \(endpoint.path)")
            return
        }

        guard response.success else {
            let error = likeError(response, fallbackCode: failureCode)
            guard idempotency.treatsAsSuccess(error) else {
                throw error
            }
            AppLogger.info("Like response treated as idempotent success: \(endpoint.path)")
            return
        }
    }

    private func likeError<T: Decodable & Equatable & Sendable>(
        _ response: LikeAPIResponseDTO<T>,
        fallbackCode: String
    ) -> NetworkError {
        if response.message.isEmpty == false {
            return .apiError(code: String(response.code), message: response.message)
        }
        return .unknown(errorCode: fallbackCode)
    }

    private nonisolated static func networkError(from error: any Error) -> NetworkError {
        if let networkError = error as? NetworkError { return networkError }
        return .unknown(errorCode: error.localizedDescription)
    }
}

private enum LikeIdempotency {
    case alreadyAdded
    case alreadyRemoved

    nonisolated func treatsAsSuccess(_ error: NetworkError) -> Bool {
        guard case let .apiError(_, message) = error else { return false }

        let normalized = message.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalized.isEmpty == false else { return false }

        switch self {
        case .alreadyAdded:
            return normalized.contains("이미") && normalized.contains("좋아요")
                || normalized.contains("already")
                || normalized.contains("duplicate")

        case .alreadyRemoved:
            return normalized.contains("좋아요") && normalized.contains("없")
                || normalized.contains("not found")
                || normalized.contains("not liked")
                || normalized.contains("존재하지")
        }
    }
}
