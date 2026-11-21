public struct ExampleCreateRequestDTO: Encodable, Equatable, Sendable {
    public let name: String

    public init(name: String) {
        self.name = name
    }
}
