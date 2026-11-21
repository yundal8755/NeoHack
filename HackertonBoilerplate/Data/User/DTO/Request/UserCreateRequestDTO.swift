import Foundation

nonisolated struct UserCreateRequestDTO: Encodable, Equatable, Sendable {
    let nickname: String
    let bio: String?

    init(nickname: String, bio: String? = nil) {
        self.nickname = nickname
        self.bio = bio
    }
}
