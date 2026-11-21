nonisolated struct UserProfileUpdateRequestDTO: Encodable {
    let update: UserProfileUpdate

    private enum CodingKeys: String, CodingKey {
        case nickname, bio, profileImagePublicId
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(update.nickname, forKey: .nickname)
        try container.encodeIfPresent(update.profileImageID, forKey: .profileImagePublicId)
        switch update.bio {
        case .set(let value): try container.encode(value, forKey: .bio)
        case .clear: try container.encodeNil(forKey: .bio)
        case nil: break
        }
    }
}
