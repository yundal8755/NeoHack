import SnapshotTesting
import SwiftUI
import UIKit
@testable import HackertonBoilerplate

extension View {
    /// 공통 컴포넌트를 아이폰 폭에 맞춰 배경과 함께 찍는다.
    func snapshotContainer(width: CGFloat = 390) -> some View {
        frame(width: width)
            .padding(AppSpacing.lg)
            .background(AppColor.background)
    }
}

extension Snapshotting where Value: SwiftUI.View, Format == UIImage {
    /// 컴포넌트용: 내용 크기만큼 라이트 모드로 렌더링한다.
    static var component: Self {
        .image(
            perceptualPrecision: 0.98,
            layout: .sizeThatFits,
            traits: UITraitCollection(userInterfaceStyle: .light)
        )
    }

    /// 화면용: 고정된 기기 크기로 라이트 모드로 렌더링한다.
    /// 탭 바·내비게이션 바(Liquid Glass)는 창에 붙어야 그려지므로 key window에 그린다.
    static var screen: Self {
        .image(
            drawHierarchyInKeyWindow: true,
            perceptualPrecision: 0.98,
            layout: .device(config: .iPhone13),
            traits: UITraitCollection(userInterfaceStyle: .light)
        )
    }
}
