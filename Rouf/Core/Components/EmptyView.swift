import SwiftUI

struct EmptyView: View {
    let title: String
    let message: String
    let systemImage: String

    init(title: String, message: String, systemImage: String = "sparkles") {
        self.title = title
        self.message = message
        self.systemImage = systemImage
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: AppSpacing.xl, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColor.accent)
                .frame(width: AppSpacing.xxl, height: AppSpacing.xxl)
                .background(AppColor.accentSoft)
                .clipShape(Circle())

            VStack(spacing: AppSpacing.xs) {
                Text(verbatim: title)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.ink)

                Text(verbatim: message)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
    }
}

#Preview {
    EmptyView(title: "No matching pieces", message: "Try MVVM, MVI, design, or resources.")
        .padding(AppSpacing.lg)
        .background(AppColor.background)
}
