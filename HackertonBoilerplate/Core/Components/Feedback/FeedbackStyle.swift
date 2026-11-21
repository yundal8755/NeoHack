import SwiftUI

struct FeedbackStyle {
    var surfaceColor = AppColor.surfaceRaised
    var borderColor = AppColor.border
    var titleColor = AppColor.ink
    var messageColor = AppColor.textSecondary
    var overlayColor = AppColor.ink.opacity(0.38)
    var shadowColor = AppColor.primary.opacity(0.12)
    var cornerRadius = AppRadius.large
    var iconSize = AppSpacing.xl
    var toastMaxWidth: CGFloat = 380
    var toastAutohideDuration: Double? = 3
    var animation = Animation.spring(response: 0.32, dampingFraction: 0.86)

    static let `default` = FeedbackStyle()

    func colors(for kind: FeedbackKind) -> FeedbackKindStyle {
        switch kind {
        case .success:
            FeedbackKindStyle(tint: AppColor.success, background: AppColor.success.opacity(0.16))
        case .info:
            FeedbackKindStyle(tint: AppColor.primary, background: AppColor.primarySoft)
        case .warning:
            FeedbackKindStyle(tint: AppColor.warning, background: AppColor.accentSoft)
        case .error:
            FeedbackKindStyle(tint: AppColor.error, background: AppColor.error.opacity(0.14))
        }
    }
}

struct FeedbackKindStyle {
    let tint: Color
    let background: Color
}
