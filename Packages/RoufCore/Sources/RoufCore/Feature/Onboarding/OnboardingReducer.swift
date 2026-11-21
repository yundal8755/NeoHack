import Foundation
import MVICore

/// 첫 실행 온보딩.
///
/// 페이지를 넘기며 서비스 소개를 보여준다. 다음 버튼은 다음 페이지로 가고, 마지막 페이지에서 누르면 온보딩을 마친다.
/// 스와이프로 페이지를 옮기면 `pageChanged`로 현재 페이지를 맞춘다.
///
/// 온보딩을 마치면 `State.isFinished`가 `true`가 된다. 화면을 띄운 쪽이 이 값을 받아 다음 화면으로 넘긴다.
public struct OnboardingReducer: Reducer {
    public init() {}

    public struct State: Equatable, Sendable {
        public let pageCount: Int
        public var currentPage: Int
        public var isFinished: Bool

        public init(pageCount: Int, currentPage: Int = 0, isFinished: Bool = false) {
            self.pageCount = max(pageCount, 1)
            self.currentPage = min(max(currentPage, 0), self.pageCount - 1)
            self.isFinished = isFinished
        }

        public var isLastPage: Bool {
            currentPage == pageCount - 1
        }
    }

    public enum Action: Equatable, Sendable {
        case nextTapped
        case pageChanged(Int)
    }

    public func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        guard !state.isFinished else { return .none }

        switch action {
        case .nextTapped:
            if state.isLastPage {
                state.isFinished = true
            } else {
                state.currentPage += 1
            }
        case .pageChanged(let page):
            guard (0..<state.pageCount).contains(page) else { break }
            state.currentPage = page
        }
        return .none
    }
}
