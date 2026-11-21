import Alamofire
import Foundation

nonisolated enum UserEndpoint {
    static func updateProfile(_ update: UserProfileUpdate, headers: [String: String]) throws -> APIEndpoint {
        try update.validate()
        if let imageID = update.profileImageID { _ = try Mapping.pathID(imageID) }
        return try APIEndpoint(
            method: .patch, path: "api/users/me", headers: headers, body: UserProfileUpdateRequestDTO(update: update))
    }
    static func profile(publicID: String) throws -> APIEndpoint {
        APIEndpoint(method: .get, path: "api/users/\(try Mapping.pathID(publicID))")
    }

    static func me(headers: [String: String]) -> APIEndpoint {
        APIEndpoint(method: .get, path: "api/users/me", headers: headers)
    }
}
