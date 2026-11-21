import PopupView
import SwiftUI

struct FeedbackPopupPresenter: ViewModifier {
    @Binding var message: FeedbackMessage?

    let presentation: FeedbackPresentation
    let style: FeedbackStyle
    let onAction: (FeedbackMessage) -> Void

    func body(content: Content) -> some View {
        content
            .popup(item: $message) { currentMessage in
                FeedbackToastView(
                    message: currentMessage,
                    presentation: presentation,
                    style: style
                ) {
                    onAction(currentMessage)
                }
            } customize: { parameters in
                switch presentation {
                case .toast(let edge):
                    parameters
                        // .toast는 safe area를 무시하므로 노치·다이내믹 아일랜드를 피하는 floater를 사용한다.
                        .type(.floater(verticalPadding: AppSpacing.xs, horizontalPadding: 0, useSafeAreaInset: true))
                        .position(edge == .top ? .top : .bottom)
                        .animation(style.animation)
                        .autohideIn(style.toastAutohideDuration)
                        .allowTapThroughBG(true)
                        .closeOnTap(true)
                case .alert:
                    parameters
                        .appearFrom(.centerScale)
                        .disappearTo(.centerScale)
                        .animation(style.animation)
                        .backgroundColor(style.overlayColor)
                        .closeOnTap(false)
                        .closeOnTapOutside(true)
                case .bottomSheet:
                    parameters
                        .type(.floater(verticalPadding: 0, horizontalPadding: AppSpacing.md, useSafeAreaInset: false))
                        .position(.bottom)
                        .appearFrom(.bottomSlide)
                        .disappearTo(.bottomSlide)
                        .animation(style.animation)
                        .backgroundColor(style.overlayColor)
                        .closeOnTap(false)
                        .closeOnTapOutside(true)
                }
            }
    }
}

extension View {
    func feedbackPopup(
        _ message: Binding<FeedbackMessage?>,
        presentation: FeedbackPresentation = .topToast,
        style: FeedbackStyle = .default,
        onAction: @escaping (FeedbackMessage) -> Void = { _ in }
    ) -> some View {
        modifier(
            FeedbackPopupPresenter(
                message: message,
                presentation: presentation,
                style: style,
                onAction: onAction
            )
        )
    }
}

#Preview("Feedback Popup Presenter") {
    FeedbackPopupPreview()
}

private struct FeedbackPopupPreview: View {
    @State private var message: FeedbackMessage?
    @State private var presentation = FeedbackPresentation.topToast

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            PrimaryButton("Show toast", systemImage: "bell.fill") {
                presentation = .topToast
                message = FeedbackMessage(
                    kind: .success,
                    title: "Saved",
                    message: "The reusable feedback presenter is ready."
                )
            }

            PrimaryButton("Show alert", systemImage: "exclamationmark.bubble.fill") {
                presentation = .alert
                message = FeedbackMessage(
                    kind: .warning,
                    title: "Needs attention",
                    message: "This demonstrates a centered PopupView-backed alert.",
                    actionTitle: "Resolve"
                )
            }

            PrimaryButton("Show bottom sheet", systemImage: "rectangle.bottomthird.inset.filled") {
                presentation = .bottomSheet
                message = FeedbackMessage(
                    kind: .info,
                    title: "Next step",
                    message: "Use this for feedback that benefits from a larger action surface.",
                    actionTitle: "Continue"
                )
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColor.background)
        .feedbackPopup($message, presentation: presentation) { selectedMessage in
            message = FeedbackMessage(
                kind: selectedMessage.kind,
                title: "Action tapped",
                message: "Handled \(selectedMessage.title)."
            )
        }
    }
}
