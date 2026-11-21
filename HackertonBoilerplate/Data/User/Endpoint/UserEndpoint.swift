import Alamofire

nonisolated enum UserEndpoint {
    static func list(headers: [String: String]) -> APIEndpoint {
        APIEndpoint(method: .get, path: "api/users", headers: headers)
    }
    static func create(nickname: String, headers: [String: String]) throws -> APIEndpoint {
        guard nickname.count <= 30 else { throw DataContractError.invalidValue("nickname") }
        return try APIEndpoint(
            method: .post, path: "api/users", headers: headers, body: UserCreateRequestDTO(nickname: nickname))
    }
    static func me(headers: [String: String]) -> APIEndpoint {
        APIEndpoint(method: .get, path: "api/users/me", headers: headers)
    }
}
