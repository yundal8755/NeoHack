import Alamofire
import Foundation

enum MovieEndpoint: TargetType {
    case list(MoviePageRequest)
    case detail(seq: Int64)

    var method: HTTPMethod {
        .get
    }

    var path: String {
        switch self {
        case .list:
            "/api/movies"
        case .detail(let seq):
            "/api/movies/\(seq)"
        }
    }

    var optionalHeaders: HTTPHeaders? {
        nil
    }

    var parameters: Parameters? {
        switch self {
        case .list(let request):
            request.parameters
        case .detail:
            nil
        }
    }

    var body: Data? {
        nil
    }

    var encodingType: EncodingType {
        .url
    }

    var requiresAuthentication: Bool {
        false
    }

    nonisolated static func imageURLString(imagePath: String) -> String? {
        guard imagePath.isEmpty == false else { return nil }
        if let components = URLComponents(string: imagePath),
           components.scheme?.isEmpty == false,
           components.host?.isEmpty == false {
            return imagePath
        }
        guard let url = ServerAPI.httpURL(from: ServerAPI.baseURL) else { return nil }
        let baseURL = url.absoluteString.hasSuffix("/") ? String(url.absoluteString.dropLast()) : url.absoluteString
        return "\(baseURL)/api/movies/image/\(encodedPathSegment(imagePath))"
    }

    nonisolated private static func encodedPathSegment(_ value: String) -> String {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/%")
        let decodedValue = value.removingPercentEncoding ?? value
        return decodedValue.addingPercentEncoding(withAllowedCharacters: allowed) ?? decodedValue
    }
}
