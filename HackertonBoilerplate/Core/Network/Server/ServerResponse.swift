import Foundation

struct ServerResponse<T: Decodable & Equatable>: Decodable, Equatable {
    let success: Bool
    let httpStatus: Int
    let data: T?
    let error: ServerErrorResponse?

    private enum CodingKeys: String, CodingKey {
        case success
        case httpStatus
        case data
        case error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.success = try container.decode(Bool.self, forKey: .success)
        self.httpStatus = try container.decode(Int.self, forKey: .httpStatus)
        self.data = try? container.decode(T.self, forKey: .data)
        if let error = try? container.decode(ServerErrorResponse.self, forKey: .error) {
            self.error = error
        } else {
            self.error = try? container.decode(ServerErrorResponse.self, forKey: .data)
        }
    }
}

struct ServerErrorResponse: Decodable, Equatable {
    let code: String
    let message: String

    private enum CodingKeys: String, CodingKey {
        case code
        case message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = (try? container.decode(String.self, forKey: .code))
            ?? (try? container.decode(Int.self, forKey: .code)).map(String.init)
            ?? "SERVER_ERROR"
        self.message = try container.decode(String.self, forKey: .message)
    }
}
