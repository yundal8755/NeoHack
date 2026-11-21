import SwiftUI

struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(verbatim: title)
        }
        .font(AppFont.headline)
        .foregroundStyle(AppColor.surfaceRaised)
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .padding(.horizontal, AppSpacing.lg)
        .background(
            Capsule()
                .fill(AppColor.primary)
        )
        .shadow(
            color: AppColor.primary.opacity(0.16),
            radius: AppSpacing.lg + AppSpacing.xxs,
            y: AppSpacing.sm
        )
        .buttonStyle(.plain)
        .asButton(action: action)
    }
}

#Preview {
    PrimaryButton("Continue", systemImage: "arrow.right") { }
        .padding(AppSpacing.lg)
        .background(AppColor.background)
}
