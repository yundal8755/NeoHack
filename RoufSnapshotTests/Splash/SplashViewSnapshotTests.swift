import SnapshotTesting
import SwiftUI
import Testing
@testable import Rouf

@MainActor
@Suite(.snapshots(record: .missing))
struct SplashViewSnapshotTests {
    /// 애니메이션이 끝나 캐릭터가 제자리에 있는 Figma 스플래시 프레임 상태.
    @Test func splashView() {
        assertSnapshot(of: SplashView(isAnimated: false), as: .screen)
    }
}
