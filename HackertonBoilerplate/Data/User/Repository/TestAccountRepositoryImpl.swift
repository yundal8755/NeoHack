import Foundation

struct TestAccountRepositoryImpl: TestAccountRepository {
    let network: NetworkManager

    func list() async throws -> [TestAccount] {
        let response = try await network.request(
            TestAccountEndpoint.list, as: APIResponseDTO<[TestAccountResponseDTO]>.self)
        return try response.value().map(Self.account)
    }

    func register(_ input: TestAccountRegistration) async throws -> TestAccount {
        let response = try await network.request(
            TestAccountEndpoint.register(input), as: APIResponseDTO<TestAccountResponseDTO>.self)
        return try Self.account(response.value())
    }

    nonisolated private static func account(_ dto: TestAccountResponseDTO) throws -> TestAccount {
        try TestAccount(
            id: Mapping.pathID(Mapping.required(dto.publicId, "publicId")),
            slot: Mapping.required(dto.slot, "slot"), nickname: Mapping.required(dto.nickname, "nickname"),
            available: Mapping.required(dto.available, "available"), profileImageID: dto.profileImagePublicId,
            profileImageURL: dto.profileImagePublicId.flatMap(ImageEndpoint.imageURL))
    }

    func claim(accountID: String) async throws -> TestAccountLease {
        let response = try await network.request(
            TestAccountEndpoint.claim(accountID: accountID), as: APIResponseDTO<TestAccountClaimDTO>.self)
        let claim = try response.value()
        guard claim.publicId == accountID else { throw DataContractError.invalidValue("publicId") }
        let token = try Mapping.required(claim.accessToken, "accessToken")
        _ = try Mapping.bearerHeaders { token }
        return try TestAccountLease(
            accountID: accountID, accessToken: token,
            expiresAt: Mapping.required(Mapping.date(claim.expiresAt, "expiresAt"), "expiresAt"))
    }

    func heartbeat(_ lease: TestAccountLease) async throws -> Date {
        let response = try await network.request(
            TestAccountEndpoint.heartbeat(lease), as: APIResponseDTO<TestAccountHeartbeatDTO>.self)
        return try Mapping.required(Mapping.date(response.value().expiresAt, "expiresAt"), "expiresAt")
    }

    func release(_ lease: TestAccountLease) async throws {
        let response = try await network.request(TestAccountEndpoint.release(lease), as: APIDeleteResponseDTO.self)
        try response.checkSuccess()
    }
}
