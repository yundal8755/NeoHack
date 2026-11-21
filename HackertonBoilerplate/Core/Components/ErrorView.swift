import SwiftUI

struct ErrorView: View {
    let title: String
    let message: String
    let retryTitle: String
    let retry: (() -> Void)?

    init(
        title: String = "Something went sideways",
        message: String,
        retryTitle: String = "Try again",
        retry: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryTitle = retryTitle
        self.retry = retry
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: AppSpacing.xl, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColor.error)

            VStack(spacing: AppSpacing.xs) {
                Text(verbatim: title)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.ink)

                Text(verbatim: message)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let retry {
                Button(action: retry) {
                    Text(verbatim: retryTitle)
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.primary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColor.primarySoft)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
    }
}

#Preview {
    ErrorView(message: "The search state could not refresh.", retry: { })
        .padding(AppSpacing.lg)
        .background(AppColor.background)
}
