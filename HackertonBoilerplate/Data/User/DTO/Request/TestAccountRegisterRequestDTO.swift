nonisolated struct TestAccountRegisterRequestDTO: Encodable, Equatable, Sendable {
    let slot: Int
    let nickname: String
    let bio: String?
}
