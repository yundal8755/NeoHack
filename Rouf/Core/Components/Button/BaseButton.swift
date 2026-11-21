import SwiftUI
import UIKit

public struct ButtonWrapper<Style: PrimitiveButtonStyle>: ViewModifier {
    public let action: () -> Void
    public let haptic: Bool
    public let style: Style

    public init(
        haptic: Bool = false,
        style: Style,
        action: @escaping () -> Void
    ) {
        self.haptic = haptic
        self.style = style
        self.action = action
    }

    public func body(content: Content) -> some View {
        Button(
            action: {
                if haptic {
                    HapticFeedbackManager.shared.impact(style: .soft)
                }

                action()
            },
            label: {
                content
                    .contentShape(Rectangle())
                    .background(Color.clear)
            }
        )
        .buttonStyle(style)
    }
}

public extension View {
    func asButton(action: @escaping () -> Void) -> some View {
        modifier(
            ButtonWrapper(
                style: .plain,
                action: action
            )
        )
    }
}
