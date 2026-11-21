import HackertonCore
import MVICore
import SnapshotTesting
import SwiftUI
import Testing
@testable import HackertonBoilerplate

@MainActor
@Suite(.snapshots(record: .missing))
struct OnboardingViewSnapshotTests {
    /// Figma 온보딩 프레임(402×874) 3장을 페이지별로 찍는다.
    @Test(arguments: [0, 1, 2])
    func onboardingView(page: Int) {
        let view = OnboardingView(store: StoreOf<OnboardingReducer>(
            state: .init(pageCount: OnboardingView.Page.all.count, currentPage: page),
            reducer: OnboardingReducer()
        ))
        assertSnapshot(
            of: view,
            as: .image(
                drawHierarchyInKeyWindow: true,
                perceptualPrecision: 0.98,
                layout: .fixed(width: 402, height: 874),
                traits: .init(userInterfaceStyle: .light)
            ),
            named: "page\(page + 1)"
        )
    }
}
