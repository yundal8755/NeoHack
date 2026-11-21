import Foundation

nonisolated struct UserEntity: Equatable, Sendable {
    let id: String
    let nickname: String
    let profileImageID: String?
    let bio: String?
    let profileImageURL: URL?

    init(id: String, nickname: String, profileImageID: String?, bio: String? = nil, profileImageURL: URL? = nil) {
        self.id = id
        self.nickname = nickname
        self.profileImageID = profileImageID
        self.bio = bio
        self.profileImageURL = profileImageURL
    }
}
