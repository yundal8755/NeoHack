import Alamofire
import Foundation

enum AuthEndpoint: TargetType {
    case login(AuthLoginRequestDTO)
    case logout

    var method: HTTPMethod {
        switch self {
        case .login, .logout:
            .post
        }
    }

    var path: String {
        switch self {
        case .login:
            "/api/auth/login"
        case .logout:
            "/auth/logout"
        }
    }

    var optionalHeaders: HTTPHeaders? {
        nil
    }

    var parameters: Parameters? {
        nil
    }

    var body: Data? {
        switch self {
        case .login(let request):
            requestToBody(request)
        case .logout:
            nil
        }
    }

    var encodingType: EncodingType {
        .json
    }

    var requiresAuthentication: Bool {
        switch self {
        case .login:
            false
        case .logout:
            true
        }
    }
}
