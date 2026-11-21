import Alamofire
import Foundation

enum LikeEndpoint: TargetType {
    case add(ticketId: Int64)
    case remove(ticketId: Int64)

    var method: HTTPMethod {
        switch self {
        case .add:
            .post
        case .remove:
            .delete
        }
    }

    var path: String {
        switch self {
        case .add(let ticketId), .remove(let ticketId):
            "/api/likes/\(ticketId)"
        }
    }

    var optionalHeaders: HTTPHeaders? {
        nil
    }

    var headers: HTTPHeaders {
        [
            "Accept": "application/json;charset=UTF-8"
        ]
    }

    var parameters: Parameters? {
        nil
    }

    var body: Data? {
        nil
    }

    var encodingType: EncodingType {
        .url
    }

    var requiresAuthentication: Bool {
        true
    }
}
