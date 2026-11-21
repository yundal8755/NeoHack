import Foundation

nonisolated public final class CodableManager: Sendable {
    
    public static let shared = CodableManager()
    
    private init () {}

    public var responseDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

extension CodableManager {
    
    nonisolated public func jsonEncoding<T: Encodable>(from value: T) throws -> Data {
        return try JSONEncoder().encode(value)
    }
    
    nonisolated public func jsonDecoding<T:Decodable>(model: T.Type, from data: Data) throws -> T {
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    nonisolated public func toJSONSerialization(data: Data?) -> Any? {
        do {
            guard let data else {
                return nil
            }
            return try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            return nil
        }
    }
}
