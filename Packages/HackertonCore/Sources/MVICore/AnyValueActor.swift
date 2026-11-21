import Foundation

public final actor AnyValueActor<Value> {
    private let defaultValue: Value
    private var value: Value

    public init(_ value: @autoclosure @Sendable () throws -> Value) rethrows {
        self.defaultValue = try value()
        self.value = defaultValue
    }
}

extension AnyValueActor {
    @discardableResult
    public func withValue<T: Sendable>(
        _ operation: @Sendable (inout Value) throws -> T
    ) rethrows -> T {
        var value = self.value
        defer { self.value = value }
        return try operation(&value)
    }

    public func setValue(_ newValue: @autoclosure @Sendable () throws -> Value) rethrows {
        self.value = try newValue()
    }

    public func resetValue() {
        value = defaultValue
    }
}
