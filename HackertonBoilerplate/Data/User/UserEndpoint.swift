import Alamofire
import Foundation

enum UserEndpoint: TargetType {
    case profile

    var method: HTTPMethod {
        .get
    }

    var path: String {
        "/user/find/profile"
    }

    var optionalHeaders: HTTPHeaders? {
        nil
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
