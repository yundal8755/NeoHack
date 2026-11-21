import SwiftUI

struct LoadingView: View {
    let message: String

    init(_ message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .tint(AppColor.primary)

            Text(verbatim: message)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
    }
}

#Preview {
    LoadingView()
        .padding(AppSpacing.lg)
        .background(AppColor.background)
}
