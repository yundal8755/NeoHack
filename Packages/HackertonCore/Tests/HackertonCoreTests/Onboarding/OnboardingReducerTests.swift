import HackertonCore
import Testing

@Suite("OnboardingReducer")
struct OnboardingReducerTests {
    typealias Feature = OnboardingReducer

    let reducer = Feature()

    @Test func 첫_페이지에서_시작한다() {
        let state = Feature.State(pageCount: 3)

        #expect(state.currentPage == 0)
        #expect(!state.isLastPage)
        #expect(!state.isFinished)
    }

    @Test(arguments: [
        (0, 1, false),
        (1, 2, false),
        (2, 2, true),
    ])
    func 다음을_누르면_다음_페이지로_가고_마지막_페이지에서는_온보딩을_마친다(from: Int, page: Int, finished: Bool) {
        var state = Feature.State(pageCount: 3, currentPage: from)

        _ = reducer.reduce(&state, with: .nextTapped)

        #expect(state.currentPage == page)
        #expect(state.isFinished == finished)
    }

    @Test(arguments: [
        (2, 2),
        (0, 0),
        (-1, 1),
        (3, 1),
    ])
    func 스와이프한_페이지가_범위_안일_때만_현재_페이지를_바꾼다(page: Int, expected: Int) {
        var state = Feature.State(pageCount: 3, currentPage: 1)

        _ = reducer.reduce(&state, with: .pageChanged(page))

        #expect(state.currentPage == expected)
    }

    @Test func 온보딩을_마친_뒤에는_입력을_무시한다() {
        var state = Feature.State(pageCount: 3, currentPage: 2, isFinished: true)

        _ = reducer.reduce(&state, with: .pageChanged(0))
        _ = reducer.reduce(&state, with: .nextTapped)

        #expect(state.currentPage == 2)
        #expect(state.isFinished)
    }

    @Test(arguments: [
        (3, -1, 0),
        (3, 5, 2),
        (0, 0, 0),
    ])
    func 시작_페이지는_범위_안으로_맞춘다(pageCount: Int, currentPage: Int, expected: Int) {
        let state = Feature.State(pageCount: pageCount, currentPage: currentPage)

        #expect(state.currentPage == expected)
    }
}
