import Testing
@testable import MVICore

/// MVICore 자체의 동작(State 반영, Effect 피드백, 취소)을 검증한다.
@Suite("Store")
@MainActor
struct StoreTests {
    @Test func 동기_Action은_즉시_State를_바꾼다() {
        let store = Store(state: CounterReducer.State(), reducer: CounterReducer())

        store.send(.increment)
        store.send(.increment)

        #expect(store.state.count == 2)
    }

    @Test func run_Effect가_보낸_Action이_State에_반영된다() async {
        let store = Store(state: CounterReducer.State(), reducer: CounterReducer())

        store.send(.delayedSet(7, delay: .zero))

        #expect(await waitUntil { store.state.count == 7 })
    }

    @Test func cancel은_진행_중인_Effect를_취소한다() async throws {
        let store = Store(state: CounterReducer.State(), reducer: CounterReducer())

        store.send(.delayedSet(7, delay: .milliseconds(50)))
        store.send(.cancelDelayed)
        try await Task.sleep(for: .milliseconds(150))

        #expect(store.state.history.isEmpty)
    }

    @Test func 같은_취소_ID로_다시_실행하면_이전_Effect는_취소된다() async throws {
        let store = Store(state: CounterReducer.State(), reducer: CounterReducer())

        store.send(.delayedSet(1, delay: .milliseconds(50)))
        store.send(.delayedSet(2, delay: .milliseconds(100)))

        #expect(await waitUntil { store.state.count == 2 })
        try await Task.sleep(for: .milliseconds(100))
        #expect(store.state.history == [2])
    }
}

// MARK: - 테스트용 Reducer

struct CounterReducer: Reducer {
    struct State: Equatable {
        var count = 0
        var history: [Int] = []
    }

    enum Action {
        case increment
        case delayedSet(Int, delay: Duration)
        case set(Int)
        case cancelDelayed
    }

    enum CancelID {
        case delayed
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .increment:
            state.count += 1
            return .none

        case let .delayedSet(value, delay):
            return .run { send in
                try? await Task.sleep(for: delay)
                await send(.set(value))
            }
            .cancelTask(id: CancelID.delayed)

        case let .set(value):
            state.count = value
            state.history.append(value)
            return .none

        case .cancelDelayed:
            return .cancel(id: CancelID.delayed)
        }
    }
}

@MainActor
func waitUntil(
    timeout: Duration = .seconds(1),
    _ condition: () -> Bool
) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now + timeout
    while condition() == false {
        guard clock.now < deadline else { return false }
        try? await Task.sleep(for: .milliseconds(5))
    }
    return true
}
