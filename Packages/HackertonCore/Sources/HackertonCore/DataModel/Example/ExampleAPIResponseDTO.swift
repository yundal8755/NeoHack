public struct ExampleAPIResponseDTO: Decodable, Equatable, Sendable {
    public let isSuccess: Bool?
    public let code: String?
    public let message: String?
    public let result: ExampleResponseDTO?
}
