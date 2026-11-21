nonisolated struct TestAccountResponseDTO: Decodable {
    let publicId: String?
    let slot: Int?
    let nickname: String?
    let profileImagePublicId: String?
    let available: Bool?
}

nonisolated struct TestAccountClaimDTO: Decodable {
    let publicId: String?
    let accessToken: String?
    let expiresAt: String?
}

nonisolated struct TestAccountHeartbeatDTO: Decodable {
    let expiresAt: String?
}
