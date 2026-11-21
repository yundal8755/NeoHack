nonisolated protocol UserRepository {
    func updateProfile(_ update: UserProfileUpdate) async throws -> UserEntity
    func me() async throws -> UserEntity
}
