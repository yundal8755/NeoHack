import Foundation

nonisolated struct TestAccount: Equatable, Identifiable, Sendable {
    let id: String
    let slot: Int
    let nickname: String
    let available: Bool
    var profileImageID: String? = nil
    var profileImageURL: URL? = nil
}

nonisolated struct TestAccountLease: Equatable, Sendable {
    let accountID: String
    let accessToken: String
    let expiresAt: Date
}

nonisolated protocol TestAccountRepository {
    func register(_ input: TestAccountRegistration) async throws -> TestAccount
    func list() async throws -> [TestAccount]
    func claim(accountID: String) async throws -> TestAccountLease
    func heartbeat(_ lease: TestAccountLease) async throws -> Date
    func release(_ lease: TestAccountLease) async throws
}
