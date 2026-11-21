import SwiftUI

extension View {
    /// 왼쪽 가장자리의 뒤로가기 swipe를 화면의 기존 닫기 동작에 연결한다.
    func swipeBack(isEnabled: Bool = true, action: @escaping () -> Void) -> some View {
        modifier(SwipeBack(isEnabled: isEnabled, action: action))
    }
}

private struct SwipeBack: ViewModifier {
    let isEnabled: Bool
    let action: () -> Void
    @Environment(\.isEnabled) private var environmentEnabled

    func body(content: Content) -> some View {
        content
            // 편집 화면에서도 시스템 pop이 변경사항 확인을 우회하지 않게 한다.
            .navigationBarBackButtonHidden(true)
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        guard isEnabled, environmentEnabled,
                            value.startLocation.x >= 0, value.startLocation.x <= 24,
                            value.translation.width > 40,
                            value.translation.width > abs(value.translation.height) * 1.5,
                            value.translation.width > 80 || value.predictedEndTranslation.width > 140
                        else { return }
                        action()
                    }
            )
    }
}
