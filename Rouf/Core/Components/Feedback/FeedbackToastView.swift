import PopupView
import SwiftUI

struct FeedbackToastView: View {
    let message: FeedbackMessage
    let presentation: FeedbackPresentation
    let style: FeedbackStyle
    let action: (() -> Void)?

    @Environment(\.popupDismiss) private var dismiss

    var body: some View {
        switch presentation {
        case .toast:
            toastBody
        case .alert:
            alertBody
        case .bottomSheet:
            bottomSheetBody
        }
    }

    private var toastBody: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            icon

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(verbatim: message.title)
                    .font(AppFont.headline)
                    .foregroundStyle(style.titleColor)

                Text(verbatim: message.message)
                    .font(AppFont.callout)
                    .foregroundStyle(style.messageColor)
                    .fixedSize(horizontal: false, vertical: true)

                actionButtonIfNeeded
            }

            Spacer(minLength: AppSpacing.xs)

            dismissButton
        }
        .feedbackCardStyle(style: style)
        .frame(maxWidth: style.toastMaxWidth)
        .padding(.horizontal, AppSpacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(message.kind.accessibilityLabel): \(message.title). \(message.message)"))
    }

    private var alertBody: some View {
        VStack(spacing: AppSpacing.md) {
            icon

            VStack(spacing: AppSpacing.xs) {
                Text(verbatim: message.title)
                    .font(AppFont.title)
                    .foregroundStyle(style.titleColor)
                    .multilineTextAlignment(.center)

                Text(verbatim: message.message)
                    .font(AppFont.callout)
                    .foregroundStyle(style.messageColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: AppSpacing.sm) {
                actionButtonIfNeeded
                closeButton(title: "OK")
            }
        }
        .frame(maxWidth: 320)
        .feedbackCardStyle(style: style)
        .padding(.horizontal, AppSpacing.lg)
        .accessibilityElement(children: .contain)
    }

    private var bottomSheetBody: some View {
        VStack(spacing: AppSpacing.md) {
            Capsule()
                .fill(AppColor.border)
                .frame(width: AppSpacing.xxl, height: AppSpacing.xxs)

            HStack(alignment: .top, spacing: AppSpacing.md) {
                icon

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(verbatim: message.title)
                        .font(AppFont.title)
                        .foregroundStyle(style.titleColor)

                    Text(verbatim: message.message)
                        .font(AppFont.callout)
                        .foregroundStyle(style.messageColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AppSpacing.sm)
            }

            actionButtonIfNeeded
            closeButton(title: "Dismiss")
        }
        .frame(maxWidth: .infinity)
        .feedbackCardStyle(style: style)
        .padding(.horizontal, AppSpacing.md)
        .accessibilityElement(children: .contain)
    }

    private var icon: some View {
        let colors = style.colors(for: message.kind)

        return Image(systemName: message.kind.systemImage)
            .font(.system(size: AppSpacing.lg, weight: .semibold, design: .rounded))
            .foregroundStyle(colors.tint)
            .frame(width: style.iconSize, height: style.iconSize)
            .background(colors.background)
            .clipShape(Circle())
            .accessibilityLabel(Text(verbatim: message.kind.accessibilityLabel))
    }

    @ViewBuilder
    private var actionButtonIfNeeded: some View {
        if let actionTitle = message.actionTitle, let action {
            Button {
                dismiss?()
                action()
            } label: {
                Text(verbatim: actionTitle)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.surfaceRaised)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .padding(.horizontal, AppSpacing.md)
                    .background(AppColor.primary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var dismissButton: some View {
        Button {
            dismiss?()
        } label: {
            Image(systemName: "xmark")
                .font(AppFont.caption)
                .foregroundStyle(style.messageColor)
                .frame(width: AppSpacing.lg, height: AppSpacing.lg)
                .background(AppColor.surface)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: "Dismiss feedback"))
    }

    private func closeButton(title: String) -> some View {
        Button {
            dismiss?()
        } label: {
            Text(verbatim: title)
                .font(AppFont.headline)
                .foregroundStyle(AppColor.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background(AppColor.primarySoft)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    func feedbackCardStyle(style: FeedbackStyle) -> some View {
        padding(AppSpacing.md)
            .background(style.surfaceColor)
            .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                    .stroke(style.borderColor)
            }
            .shadow(color: style.shadowColor, radius: 20, y: 10)
    }
}

#Preview("Toast") {
    FeedbackToastView(
        message: FeedbackMessage(
            kind: .success,
            title: "Profile saved",
            message: "Your changes are ready for the next API sync."
        ),
        presentation: .topToast,
        style: .default,
        action: nil
    )
    .padding(AppSpacing.lg)
    .background(AppColor.background)
}

#Preview("Alert") {
    FeedbackToastView(
        message: FeedbackMessage(
            kind: .warning,
            title: "Review required",
            message: "Check the payload before sending it to the server.",
            actionTitle: "Open review"
        ),
        presentation: .alert,
        style: .default,
        action: { }
    )
    .padding(AppSpacing.lg)
    .background(AppColor.background)
}
