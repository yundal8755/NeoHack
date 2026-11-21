import MVICore
import Testing

/// TCA의 TestStore를 작게 흉내 낸 Reducer 테스트 도우미.
///
/// ```swift
/// let tester = ReducerTester(LoginReducer(repository: mock), state: .init())
/// await tester.send(.loginTapped) { $0.isLoading = true }
/// await tester.receive({ if case .loginResponse = $0 { true } else { false } }) {
///     $0.isLoading = false
/// }
/// tester.finish()
/// ```
///
/// - `send`: Action을 보내고 기대하는 State 변화를 클로저로 적는다. `.run` Effect는 끝날 때까지 실행하고,
///   그 안에서 보낸 Action은 대기열에 쌓는다.
/// - `receive`: 대기열의 다음 Action을 확인하고 Reducer에 다시 넣는다.
/// - `finish`: 확인하지 않은 Action이 남아 있으면 실패시킨다.
@MainActor
public final class ReducerTester<R: Reducer> where R.State: Equatable {
    public private(set) var state: R.State
    public private(set) var pendingActions: [R.Action] = []

    private let reducer: R

    public init(_ reducer: R, state: R.State) {
        self.reducer = reducer
        self.state = state
    }

    public func send(
        _ action: R.Action,
        _ update: (inout R.State) -> Void = { _ in },
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        var expected = state
        update(&expected)

        let effect = reducer.reduce(&state, with: action)
        #expect(state == expected, "State가 기대와 다름", sourceLocation: sourceLocation)

        pendingActions += await run(effect)
    }

    public func receive(
        _ matches: (R.Action) -> Bool,
        _ update: (inout R.State) -> Void = { _ in },
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        guard let next = pendingActions.first else {
            Issue.record("받을 Action이 없음", sourceLocation: sourceLocation)
            return
        }
        guard matches(next) else {
            Issue.record("기대와 다른 Action이 먼저 옴: \(next)", sourceLocation: sourceLocation)
            return
        }

        pendingActions.removeFirst()
        await send(next, update, sourceLocation: sourceLocation)
    }

    public func finish(sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(
            pendingActions.isEmpty,
            "처리되지 않은 Action: \(pendingActions)",
            sourceLocation: sourceLocation
        )
    }

    private func run(_ effect: Effect<R.Action>) async -> [R.Action] {
        guard case let .run(_, operation) = effect.caseOf else { return [] }

        let recorder = ActionRecorder<R.Action>()
        await operation { action in
            await recorder.append(action)
        }
        return await recorder.actions
    }
}

private actor ActionRecorder<Action> {
    private(set) var actions: [Action] = []

    func append(_ action: Action) {
        actions.append(action)
    }
}
