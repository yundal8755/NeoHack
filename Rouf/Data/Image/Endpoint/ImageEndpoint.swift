import Alamofire
import Foundation

nonisolated enum ImageEndpoint {
    static func upload(headers: [String: String]) -> APIEndpoint {
        APIEndpoint(method: .post, path: "api/images", headers: headers)
    }
    static func uploadStep(headers: [String: String]) -> APIEndpoint {
        APIEndpoint(method: .post, path: "api/images/step", headers: headers)
    }
    static func uploadProfile(headers: [String: String]) -> APIEndpoint {
        APIEndpoint(method: .post, path: "api/images/profile", headers: headers)
    }
    static func data(id: String) throws -> APIEndpoint {
        APIEndpoint(method: .get, path: try imagePath(id), headers: ["Accept": "*/*"])
    }

    static func imageURL(id: String) -> URL? {
        guard let path = try? imagePath(id) else { return nil }
        return ServerAPI.httpURL(from: ServerAPI.baseURL)?.appending(path: path)
    }

    private static func imagePath(_ id: String) throws -> String {
        "api/images/\(try Mapping.pathID(id))"
    }
}
