import Alamofire
import Foundation

final class NetworkManager {
    private let authInterceptor: AuthInterceptor?
    private let session: Session

    init(authInterceptor: AuthInterceptor? = nil, session: Session = .default) {
        self.session = session
        self.authInterceptor = authInterceptor
    }

    func request<T: Decodable, R: TargetType>(
        _ target: R,
        as dto: T.Type
    ) async throws(NetworkError) -> T {
        try await request(target, as: dto, allowsTokenRefresh: true)
    }

    func requestData<R: TargetType>(
        _ target: R,
        maxResponseBytes: Int = 10 * 1024 * 1024
    ) async throws(NetworkError) -> Data {
        try await requestData(target, maxResponseBytes: maxResponseBytes, allowsTokenRefresh: true)
    }

    func upload<T: Decodable, R: TargetType>(
        _ target: R, file: Data, fileName: String, mimeType: String, as dto: T.Type
    ) async throws(NetworkError) -> T {
        var request = try makeRequest(for: target)
        // Alamofire가 boundary를 포함한 Content-Type을 설정한다.
        request.setValue(nil, forHTTPHeaderField: "Content-Type")
        let response = await session.upload(multipartFormData: { form in
            form.append(file, withName: "file", fileName: fileName, mimeType: mimeType)
        }, with: request)
            .validate(statusCode: 200..<300)
            .serializingDecodable(dto, decoder: CodableManager.shared.responseDecoder)
            .response
        return try parseResponse(response)
    }

}

private extension NetworkManager {

    func request<T: Decodable, R: TargetType>(
        _ target: R,
        as dto: T.Type,
        allowsTokenRefresh: Bool
    ) async throws(NetworkError) -> T {
        let urlRequest = try makeRequest(for: target)
        AppLogger.debug("Request: \(target.method.rawValue) \(target.path)")
        let response = await performRequest(dtoType: dto, request: urlRequest)

        do {
            let parsed = try parseResponse(response)
            AppLogger.debug("Response success: \(target.method.rawValue) \(target.path) status=\(response.response?.statusCode ?? 0)")
            return parsed
        } catch let error {
            AppLogger.warning("Response failure: \(target.method.rawValue) \(target.path) error=\(error)")
            guard case .httpStatusCode(401) = error,
                  target.requiresAuthentication,
                  allowsTokenRefresh else {
                throw error
            }

            guard let refreshedToken = try await authInterceptor?.refreshAccessToken(), refreshedToken.isEmpty == false else {
                AppLogger.error("Token refresh failed")
                authInterceptor?.expireSession()
                throw .refreshFailGoRoot
            }

            AppLogger.info("Token refresh succeeded; retrying request: \(target.path)")
            return try await request(target, as: dto, allowsTokenRefresh: false)
        }
    }

    func requestData<R: TargetType>(
        _ target: R,
        maxResponseBytes: Int,
        allowsTokenRefresh: Bool
    ) async throws(NetworkError) -> Data {
        let urlRequest = try makeRequest(for: target)
        AppLogger.debug("Request data: \(target.method.rawValue) \(target.path)")
        let response = await performDataRequest(request: urlRequest)

        do {
            let parsed = try parseDataResponse(response, maxResponseBytes: maxResponseBytes)
            AppLogger.debug("Response data success: \(target.method.rawValue) \(target.path) status=\(response.response?.statusCode ?? 0)")
            return parsed
        } catch let error {
            AppLogger.warning("Response data failure: \(target.method.rawValue) \(target.path) error=\(error)")
            guard case .httpStatusCode(401) = error,
                  target.requiresAuthentication,
                  allowsTokenRefresh else {
                throw error
            }

            guard let refreshedToken = try await authInterceptor?.refreshAccessToken(), refreshedToken.isEmpty == false else {
                AppLogger.error("Token refresh failed")
                authInterceptor?.expireSession()
                throw .refreshFailGoRoot
            }

            AppLogger.info("Token refresh succeeded; retrying data request: \(target.path)")
            return try await requestData(target, maxResponseBytes: maxResponseBytes, allowsTokenRefresh: false)
        }
    }

    func makeRequest<R: TargetType>(for target: R) throws(NetworkError) -> URLRequest {
        do {
            let request = try target.asURLRequest()
            return authInterceptor?.adapt(request, for: target) ?? request
        } catch {
            AppLogger.error("Request creation failed: \(target.path) error=\(error)")
            throw NetworkError(error)
        }
    }

    func performRequest<T: Decodable>(
        dtoType: T.Type,
        request: URLRequest
    ) async -> DataResponse<T, AFError> {
        await session.request(request)
            .validate(statusCode: 200..<300)
            .serializingDecodable(dtoType, decoder: CodableManager.shared.responseDecoder)
            .response
    }

    func performDataRequest(request: URLRequest) async -> DataResponse<Data, AFError> {
        await session.request(request)
            .validate(statusCode: 200..<300)
            .serializingData()
            .response
    }

    func parseResponse<T: Decodable>(
        _ response: DataResponse<T, AFError>
    ) throws(NetworkError) -> T {
        switch response.result {
        case .success(let data):
            return data
        case .failure(let error):
            if error.isExplicitlyCancelledError {
                throw .cancel
            }

            if error.isSessionTaskError,
               let underlyingError = error.underlyingError as NSError?,
               underlyingError.domain == NSURLErrorDomain {
                switch underlyingError.code {
                case NSURLErrorTimedOut:
                    throw .timeOut
                case NSURLErrorNotConnectedToInternet,
                     NSURLErrorNetworkConnectionLost,
                     NSURLErrorCannotFindHost,
                     NSURLErrorCannotConnectToHost:
                    throw .networkUnavailable
                default:
                    throw .unknown(errorCode: String(underlyingError.code))
                }
            }

            if let serverError = decodeServerError(from: response.data) {
                throw .apiError(code: serverError.code, message: serverError.message)
            }

            if let statusCode = response.response?.statusCode,
               (200..<300).contains(statusCode) == false {
                throw .httpStatusCode(statusCode)
            }

            throw .decodingFail
        }
    }

    func parseDataResponse(
        _ response: DataResponse<Data, AFError>,
        maxResponseBytes: Int
    ) throws(NetworkError) -> Data {
        switch response.result {
        case .success(let data):
            guard data.count <= maxResponseBytes else {
                throw .unknown(errorCode: "RESPONSE_TOO_LARGE")
            }
            return data
        case .failure(let error):
            if error.isExplicitlyCancelledError {
                throw .cancel
            }

            if error.isSessionTaskError,
               let underlyingError = error.underlyingError as NSError?,
               underlyingError.domain == NSURLErrorDomain {
                switch underlyingError.code {
                case NSURLErrorTimedOut:
                    throw .timeOut
                case NSURLErrorNotConnectedToInternet,
                     NSURLErrorNetworkConnectionLost,
                     NSURLErrorCannotFindHost,
                     NSURLErrorCannotConnectToHost:
                    throw .networkUnavailable
                default:
                    throw .unknown(errorCode: String(underlyingError.code))
                }
            }

            if let serverError = decodeServerError(from: response.data) {
                throw .apiError(code: serverError.code, message: serverError.message)
            }

            if let statusCode = response.response?.statusCode,
               (200..<300).contains(statusCode) == false {
                throw .httpStatusCode(statusCode)
            }

            throw .decodingFail
        }
    }

    func decodeServerError(from data: Data?) -> ServerErrorResponse? {
        guard let data else { return nil }

        let decoder = CodableManager.shared.responseDecoder
        if let error = try? decoder.decode(ServerErrorResponse.self, from: data) {
            return error
        }

        return try? decoder.decode(ServerErrorEnvelope.self, from: data).serverError
    }
}

private struct ServerErrorEnvelope: Decodable {
    let serverError: ServerErrorResponse?

    private enum CodingKeys: String, CodingKey {
        case data
        case error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let error = try? container.decode(ServerErrorResponse.self, forKey: .error) {
            self.serverError = error
        } else {
            self.serverError = try? container.decode(ServerErrorResponse.self, forKey: .data)
        }
    }
}
