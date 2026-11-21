import Alamofire

nonisolated enum ImageEndpoint {
    static func upload(headers: [String: String]) -> APIEndpoint {
        APIEndpoint(method: .post, path: "api/images", headers: headers)
    }
    static func data(id: String) throws -> APIEndpoint {
        APIEndpoint(method: .get, path: "api/images/\(try Mapping.pathID(id))", headers: ["Accept": "*/*"])
    }
}
