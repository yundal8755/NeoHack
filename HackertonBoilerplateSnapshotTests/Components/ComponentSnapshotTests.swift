import SnapshotTesting
import SwiftUI
import Testing
@testable import HackertonBoilerplate

/// 공통 컴포넌트가 깨지지 않는지 확인한다.
/// 기준 이미지는 __Snapshots__에 있고, 없으면 첫 실행에서 기록한 뒤 실패한다(다시 실행하면 통과).
@MainActor
@Suite(.snapshots(record: .missing))
struct ComponentSnapshotTests {
    @Test func loadingView() {
        assertSnapshot(of: LoadingView().snapshotContainer(), as: .component)
    }

    @Test func emptyView() {
        let view = HackertonBoilerplate.EmptyView(title: "아직 내용이 없어요", message: "새 항목을 추가하면 여기에 보여요.")
        assertSnapshot(of: view.snapshotContainer(), as: .component)
    }

    @Test(arguments: [true, false])
    func errorView(hasRetry: Bool) {
        let view = ErrorView(message: "잠시 후 다시 시도해 주세요.", retry: hasRetry ? {} : nil)
        assertSnapshot(of: view.snapshotContainer(), as: .component, named: hasRetry ? "retry" : "noRetry")
    }

    @Test(arguments: [nil, "arrow.right"] as [String?])
    func primaryButton(systemImage: String?) {
        let view = PrimaryButton("계속하기", systemImage: systemImage) {}
        assertSnapshot(of: view.snapshotContainer(), as: .component, named: systemImage == nil ? "text" : "icon")
    }
}
