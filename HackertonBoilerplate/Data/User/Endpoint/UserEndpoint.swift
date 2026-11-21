import Alamofire
import Foundation

nonisolated enum UserEndpoint {
    static func list(headers: [String: String]) -> APIEndpoint {
        APIEndpoint(method: .get, path: "api/users", headers: headers)
    }
    static func create(nickname: String, bio: String? = nil, headers: [String: String]) throws -> APIEndpoint {
        guard nickname.count <= 30 else { throw DataContractError.invalidValue("nickname") }
        if let bio {
            let lineBreaks = CharacterSet(charactersIn: "\r\n\u{000B}\u{000C}\u{0085}\u{2028}\u{2029}")
            guard bio.count <= 100, bio.rangeOfCharacter(from: lineBreaks) == nil else {
                throw DataContractError.invalidValue("bio")
            }
        }
        return try APIEndpoint(
            method: .post, path: "api/users", headers: headers, body: UserCreateRequestDTO(nickname: nickname, bio: bio))
    }
    static func updateProfile(_ update: UserProfileUpdate, headers: [String: String]) throws -> APIEndpoint {
        try update.validate()
        if let imageID = update.profileImageID { _ = try Mapping.pathID(imageID) }
        return try APIEndpoint(
            method: .patch, path: "api/users/me", headers: headers, body: UserProfileUpdateRequestDTO(update: update))
    }
    static func me(headers: [String: String]) -> APIEndpoint {
        APIEndpoint(method: .get, path: "api/users/me", headers: headers)
    }
}
