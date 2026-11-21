import Combine
import Foundation

@MainActor
final class ProfileAccounts: ObservableObject {
    private let container: AppContainer
    @Published private(set) var session: ProfileSession?
    @Published private(set) var entries: [TestAccount] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    /// 선택해서 계정을 받아오는 중인 계정 ID. 카드의 연결 중 표시에 쓴다.
    @Published private(set) var connectingID: String?
    private var lease: TestAccountLease?
    private var keepAlive: Task<Void, Never>?

    init(container: AppContainer) {
        self.container = container
    }

    func load() async {
        guard session == nil, !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do { entries = try await container.testAccounts.list() }
        catch { if !Task.isCancelled { self.error = error.localizedDescription } }
    }

    func choose(_ account: TestAccount) {
        guard account.available, !isLoading, session == nil else { return }
        isLoading = true
        connectingID = account.id
        error = nil
        Task {
            defer {
                isLoading = false
                connectingID = nil
            }
            do {
                let claimed = try await container.testAccounts.claim(accountID: account.id)
                do {
                    let repositories = container.session(token: claimed.accessToken)
                    let profile = try await repositories.users.me()
                    guard profile.id == account.id else { throw ProfileSelectionError.profileMismatch }
                    lease = claimed
                    session = ProfileSession(profile: profile, repositories: repositories)
                    startHeartbeat(claimed)
                } catch {
                    try? await container.testAccounts.release(claimed)
                    throw error
                }
            } catch {
                entries = (try? await container.testAccounts.list()) ?? entries
                self.error = error.localizedDescription
            }
        }
    }

    func dismissError() {
        error = nil
    }

    func signOut() {
        guard let lease, !isLoading else { return }
        keepAlive?.cancel()
        keepAlive = nil
        self.lease = nil
        entries = []
        isLoading = true
        session = nil
        Task {
            defer { isLoading = false }
            do { try await container.testAccounts.release(lease) }
            catch { if !Self.isExpired(error) { self.error = error.localizedDescription } }
            do { entries = try await container.testAccounts.list() }
            catch { self.error = error.localizedDescription }
        }
    }

    private func startHeartbeat(_ lease: TestAccountLease) {
        keepAlive?.cancel()
        keepAlive = Task { [weak self] in
            var expiresAt = lease.expiresAt
            var delay: Duration = .seconds(30)
            while !Task.isCancelled {
                do { try await Task.sleep(for: delay) } catch { return }
                guard let self else { return }
                do {
                    expiresAt = try await self.container.testAccounts.heartbeat(lease)
                    delay = .seconds(30)
                } catch {
                    guard !Task.isCancelled else { return }
                    if Self.isExpired(error) || Date() >= expiresAt {
                        self.lease = nil
                        self.entries = []
                        self.session = nil
                        await self.load()
                        self.error = "계정 사용권이 만료됐어요. 다시 선택해 주세요."
                        return
                    }
                    delay = .seconds(5)
                }
            }
        }
    }

    private static func isExpired(_ error: Error) -> Bool {
        switch error as? NetworkError {
        case .apiError(code: "TEST401", message: _), .httpStatusCode(401): true
        default: false
        }
    }
}

private enum ProfileSelectionError: LocalizedError {
    case profileMismatch
    var errorDescription: String? { "선택한 프로필을 확인하지 못했어요." }
}
