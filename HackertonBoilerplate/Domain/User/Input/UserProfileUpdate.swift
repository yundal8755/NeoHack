import Foundation

nonisolated struct UserProfileUpdate: Equatable, Sendable {
    enum BioChange: Equatable, Sendable {
        case set(String)
        case clear
    }

    var nickname: String? = nil
    var bio: BioChange? = nil
    var profileImageID: String? = nil

    func validate() throws {
        if let nickname, !(2...10).contains(nickname.count) {
            throw ValidationError.nickname
        }
        if case let .set(value) = bio,
            value.count > 50 || value.contains(where: \.isNewline)
        {
            throw ValidationError.bio
        }
    }

    enum ValidationError: LocalizedError {
        case nickname, bio
        var errorDescription: String? {
            switch self {
            case .nickname: "닉네임을 2~10자로 입력해 주세요."
            case .bio: "한 줄 소개는 줄바꿈 없이 50자까지 입력할 수 있어요."
            }
        }
    }
}
