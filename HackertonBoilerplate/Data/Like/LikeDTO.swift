import Foundation

nonisolated struct LikeAPIResponseDTO<T: Decodable & Equatable & Sendable>: Decodable, Equatable, Sendable {
    let code: Int
    let message: String
    let data: T?

    private enum CodingKeys: String, CodingKey {
        case code
        case message
        case data
    }

    var success: Bool {
        code == 0 || (200..<300).contains(code)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = (try? container.decode(Int.self, forKey: .code))
            ?? Int((try? container.decode(String.self, forKey: .code)) ?? "")
            ?? 0
        message = (try? container.decode(String.self, forKey: .message)) ?? ""
        data = try? container.decodeIfPresent(T.self, forKey: .data)
    }
}
