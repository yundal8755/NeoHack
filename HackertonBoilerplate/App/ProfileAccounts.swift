import Combine
import Foundation

@MainActor
final class ProfileAccounts: ObservableObject {
    enum Slot: String, CaseIterable, Identifiable {
        case user1, user2
        var id: String { rawValue }

        var keychain: KeychainTokenStore {
            KeychainTokenStore(account: "neo.profile.\(rawValue)")
        }
    }

    private let container: AppContainer
    @Published private(set) var session: ProfileSession?
    private var slot: Slot?
    @Published var token = ""
    @Published private(set) var candidates: [UserEntity] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published private(set) var needsToken = false

    init(container: AppContainer) {
        self.container = container
    }

    func signOut() {
        session = nil
        resetSelection()
    }

    func tokenChanged() { candidates = [] }

    func submitToken() {
        guard let slot else { return }
        let value = token.trimmingCharacters(in: .whitespacesAndNewlines)
        run { try await self.discoverProfiles(slot, token: value) }
    }

    func select(_ user: UserEntity) {
        guard let slot else { return }
        let value = token.trimmingCharacters(in: .whitespacesAndNewlines)
        run { try await self.open(slot, token: value, userID: user.id, save: true) }
    }

    private func resetSelection() {
        slot = nil
        token = ""
        candidates = []
        error = nil
        needsToken = false
    }

    func choose(_ slot: Slot) {
        resetSelection()
        self.slot = slot
        if let saved = slot.keychain.accessToken,
            let credentials = try? JSONDecoder().decode(SlotCredentials.self, from: Data(saved.utf8))
        {
            run { [self] in
                do { try await open(slot, token: credentials.token, userID: credentials.userID, save: false) } catch {
                    switch error as? NetworkError {
                    case .apiError(let code, _) where code == "USER404" || code == "COMMON404":
                        needsToken = true
                    case .httpStatusCode(404):
                        needsToken = true
                    default:
                        break
                    }
                    throw error
                }
            }
        } else {
            needsToken = true
        }
    }

    private func run(_ operation: @escaping @MainActor () async throws -> Void) {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        Task {
            defer { isLoading = false }
            do { try await operation() } catch { self.error = error.localizedDescription }
        }
    }

    private func discoverProfiles(_ slot: Slot, token: String) async throws {
        candidates = []
        let users = try await container.profiles(deviceToken: token).list()
        if let only = users.first, users.count == 1 {
            try await open(slot, token: token, userID: only.id, save: true)
        } else if users.isEmpty {
            error = "이 기기 토큰에 연결된 프로필이 없어요."
        } else {
            candidates = users
        }
    }

    private func open(_ slot: Slot, token: String, userID: String, save: Bool) async throws {
        let repositories = container.session(token: token, userID: userID)
        let profile = try await repositories.users.me()
        guard profile.id == userID else { throw ProfileSelectionError.profileMismatch }
        if save {
            let bytes = try JSONEncoder().encode(SlotCredentials(token: token, userID: userID))
            let encoded = String(decoding: bytes, as: UTF8.self)
            slot.keychain.accessToken = encoded
            guard slot.keychain.accessToken == encoded else {
                throw ProfileSelectionError.storageFailed
            }
        }
        resetSelection()
        session = ProfileSession(profile: profile, repositories: repositories)
    }
}

private struct SlotCredentials: Codable {
    let token: String
    let userID: String
}

private enum ProfileSelectionError: LocalizedError {
    case profileMismatch, storageFailed
    var errorDescription: String? {
        switch self {
        case .profileMismatch: "선택한 프로필을 확인하지 못했어요."
        case .storageFailed: "계정 설정을 저장하지 못했어요. 다시 시도해 주세요."
        }
    }
}
