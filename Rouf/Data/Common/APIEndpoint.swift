import Alamofire
import Foundation

nonisolated struct APIEndpoint: TargetType {
    let method: HTTPMethod
    let path: String
    var optionalHeaders: HTTPHeaders? = nil
    var parameters: Parameters? = nil
    var body: Data? = nil
    var encodingType: EncodingType = .url

    init(method: HTTPMethod, path: String, headers: [String: String] = [:], parameters: Parameters? = nil) {
        self.method = method
        self.path = path
        self.optionalHeaders = HTTPHeaders(headers)
        self.parameters = parameters
    }
    init<Body: Encodable>(method: HTTPMethod, path: String, headers: [String: String], body: Body) throws {
        self.init(method: method, path: path, headers: headers)
        self.body = try CodableManager.shared.jsonEncoding(from: body)
        self.encodingType = .json
    }
}
