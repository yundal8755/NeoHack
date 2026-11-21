import MVICore
import MVITestSupport
import Testing

/// ReducerTester가 맞는 흐름은 통과시키고, 틀린 흐름은 실패로 기록하는지 검증한다.
@Suite("ReducerTester")
@MainActor
struct ReducerTesterTests {
    @Test func send와_receive로_Effect_피드백까지_검증한다() async {
        let tester = ReducerTester(CounterReducer(), state: .init())

        await tester.send(.delayedSet(3, delay: .zero))
        await tester.receive({ if case .set(3) = $0 { true } else { false } }) {
            $0.count = 3
            $0.history = [3]
        }
        tester.finish()
    }

    @Test func State가_기대와_다르면_실패를_기록한다() async {
        let tester = ReducerTester(CounterReducer(), state: .init())

        await withKnownIssue {
            await tester.send(.increment) { $0.count = 2 }
        }
    }

    @Test func 처리하지_않은_Action이_남으면_finish가_실패를_기록한다() async {
        let tester = ReducerTester(CounterReducer(), state: .init())
        await tester.send(.delayedSet(1, delay: .zero))

        withKnownIssue {
            tester.finish()
        }
    }

    @Test func 기대와_다른_Action이_오면_실패를_기록한다() async {
        let tester = ReducerTester(CounterReducer(), state: .init())
        await tester.send(.delayedSet(1, delay: .zero))

        await withKnownIssue {
            await tester.receive({ if case .increment = $0 { true } else { false } })
        }
    }

    @Test func unimplemented_의존성이_호출되면_실패를_기록한다() async {
        let login: @Sendable (String) async throws -> Int = unimplemented("login")

        await withKnownIssue {
            _ = try? await login("a@b.com")
        }
    }
}
