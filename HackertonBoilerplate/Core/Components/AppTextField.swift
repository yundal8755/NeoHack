import SwiftUI

/// Figma `Input` 컴포넌트. 흰 배경, 회색 테두리, 14pt 본문.
/// - `axis: .vertical`이면 입력이 길어질 때 최대 4줄(Figma 최대 높이 100)까지 늘어난다.
/// - `maxLength`를 주면 그 길이를 넘는 입력을 잘라낸다.
struct AppTextField: View {
    let placeholder: String
    let systemImage: String?
    let axis: Axis
    let maxLength: Int?
    @Binding var text: String

    init(
        _ placeholder: String,
        systemImage: String? = nil,
        text: Binding<String>,
        axis: Axis = .horizontal,
        maxLength: Int? = nil
    ) {
        self.placeholder = placeholder
        self.systemImage = systemImage
        self.axis = axis
        self.maxLength = maxLength
        self._text = text
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(AppColor.textSecondary)
            }

            TextField(
                "",
                text: $text,
                prompt: Text(verbatim: placeholder).foregroundStyle(AppColor.textTertiary),
                axis: axis
            )
            .lineLimit(axis == .vertical ? 1...4 : 1...1)
            .font(Self.textStyle.font)
            .lineSpacing(Self.textStyle.extraLineSpacing)
            // placeholder와 입력 텍스트의 높이가 같도록 한 줄 높이를 Figma 값으로 고정한다.
            .frame(
                minHeight: Self.textStyle.lineHeight,
                maxHeight: axis == .horizontal ? Self.textStyle.lineHeight : nil
            )
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(AppColor.textInput)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .onChange(of: text) { _, newValue in
                guard let maxLength, newValue.count > maxLength else { return }
                text = String(newValue.prefix(maxLength))
            }
        }
        .padding(.horizontal, AppSpacing.inputHorizontal)
        .padding(.vertical, AppSpacing.inputVertical)
        // Figma 테두리(1pt)는 안쪽 여백 바깥에 있다.
        .padding(Self.borderWidth)
        .background(AppColor.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.input, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.input, style: .continuous)
                .strokeBorder(AppColor.border, lineWidth: Self.borderWidth)
        }
    }

    private static let textStyle = AppFont.caption1
    private static let borderWidth: CGFloat = 1
}

#Preview {
    @Previewable @State var title = ""
    @Previewable @State var content = "아침에 역시나 사람이 많아요. 지하철 사람들이 모두 회색 인간인 것 같아요."
    VStack(spacing: AppSpacing.md) {
        AppTextField("5자에서 30자까지 입력해 주세요.", text: $title, maxLength: 30)
        AppTextField("최대 100자까지 입력 가능합니다.", text: $content, axis: .vertical, maxLength: 100)
    }
    .padding(AppSpacing.md)
}
