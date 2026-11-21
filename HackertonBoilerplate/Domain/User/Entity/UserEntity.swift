import Foundation

nonisolated struct UserEntity: Equatable, Sendable {
    let id: String
    let nickname: String
    let profileImageID: String?
    let bio: String?

    init(id: String, nickname: String, profileImageID: String?, bio: String? = nil) {
        self.id = id
        self.nickname = nickname
        self.profileImageID = profileImageID
        self.bio = bio
    }
}
