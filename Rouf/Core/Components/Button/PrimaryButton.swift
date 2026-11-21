import SwiftUI

/// Figma `버튼` 컴포넌트.
/// - `.primary`: 주 동작(다음, 완료, 확인). Primary/500 배경.
/// - `.secondary`: 보조 동작(시간 선택 시트의 취소). 연한 회색 배경.
/// - `.disabled(true)`를 걸면 Figma Default 상태(회색 배경, 회색 글자)로 그린다.
///
/// 폭은 부모에 맞춰 늘어난다. 두 버튼을 나란히 둘 때는 `HStack`에 넣는다.
struct PrimaryButton: View {
    enum Style {
        case primary
        case secondary
    }

    let title: String
    let systemImage: String?
    let style: Style
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String? = nil,
        style: Style = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(verbatim: title)
            }
        }
        .buttonStyle(AppButtonStyle(style: style))
    }
}

private struct AppButtonStyle: ButtonStyle {
    let style: PrimaryButton.Style
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appFont(isEnabled ? AppFont.body2 : AppFont.body2.weight(.medium))
            .foregroundStyle(foreground)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.buttonPadding)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                    .fill(background)
            )
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }

    private var foreground: Color {
        guard isEnabled else { return AppColor.textDisabled }
        return switch style {
        case .primary: AppColor.white
        case .secondary: AppColor.textPrimary
        }
    }

    private var background: Color {
        guard isEnabled else { return AppColor.fillDisabled }
        return switch style {
        case .primary: AppColor.primary
        case .secondary: AppColor.surface
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        PrimaryButton("다음") {}
        PrimaryButton("다음") {}
            .disabled(true)
        HStack(spacing: AppSpacing.sm) {
            PrimaryButton("취소", style: .secondary) {}
            PrimaryButton("확인") {}
        }
    }
    .padding(AppSpacing.md)
}
