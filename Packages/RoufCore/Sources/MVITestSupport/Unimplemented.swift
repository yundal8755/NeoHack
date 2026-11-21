import Testing

/// 호출되면 안 되는 의존성 자리에 넣는다. 호출되면 테스트를 실패로 기록하고 에러를 던진다.
///
/// ```swift
/// let repository = MockAuthRepository(login: unimplemented("login"))
/// ```
public func unimplemented<Input, Output>(
    _ name: String,
    sourceLocation: SourceLocation = #_sourceLocation
) -> @Sendable (Input) async throws -> Output {
    { _ in
        Issue.record("\(name)이(가) 예상치 않게 호출됨", sourceLocation: sourceLocation)
        throw UnimplementedError(name: name)
    }
}

public struct UnimplementedError: Error, Equatable {
    public let name: String
}
