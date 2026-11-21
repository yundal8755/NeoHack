import Alamofire
import Foundation

struct HealthRepositoryImpl: HealthRepository {
    let network: NetworkManager

    func status() async throws -> String {
        let endpoint = APIEndpoint(method: .get, path: "health", headers: ["Accept": "text/plain"])
        let bytes = try await network.requestData(endpoint)
        guard let status = String(data: bytes, encoding: .utf8) else { throw NetworkError.decodingFail }
        return status
    }
}
