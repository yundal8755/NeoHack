import SnapshotTesting
import UIKit
import SwiftUI
import Testing
@testable import Rouf

/// 사용자 선택 화면을 상태별로 찍는다.
@MainActor
@Suite(.snapshots(record: .missing))
struct AccountSelectViewSnapshotTests {
    @Test(arguments: ["list", "connecting", "loading", "empty", "error"])
    func accountSelectView(state: String) {
        let view: AccountSelectView = switch state {
        case "list": AccountSelectView(entries: TestAccount.previewEntries)
        case "connecting": AccountSelectView(entries: TestAccount.previewEntries, connectingID: "2", isLoading: true)
        case "loading": AccountSelectView(entries: [], isLoading: true)
        case "empty": AccountSelectView(entries: [])
        default: AccountSelectView(entries: [], error: "서버에 연결하지 못했어요.")
        }
        assertSnapshot(of: view, as: .windowlessScreen, named: state)
    }
}

private extension Snapshotting where Value: SwiftUI.View, Format == UIImage {
    /// 기기 크기로 찍되 key window에 그리지 않는다.
    /// 이 화면에는 Liquid Glass 바가 없고, key window에 그리면 진행 표시 애니메이션이 매번 다른 프레임으로 찍힌다.
    static var windowlessScreen: Self {
        .image(
            perceptualPrecision: 0.98,
            layout: .device(config: .iPhone13),
            traits: UITraitCollection(userInterfaceStyle: .light)
        )
    }
}
