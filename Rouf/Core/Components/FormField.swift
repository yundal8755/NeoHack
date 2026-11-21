import SwiftUI

/// 입력 항목 하나: 제목(필수면 빨간 *), 안내 문구, 입력 컨트롤.
/// Figma 루틴 입력 카드·루틴 소개 화면의 `제목/내용/루틴 제목/루틴 소개` 블록.
///
/// ```swift
/// FormField("제목", guide: "5자에서 30자까지 입력해 주세요.", isRequired: true) {
///     AppTextField("5자에서 30자까지 입력해 주세요.", text: $title, maxLength: 30)
/// }
/// ```
struct FormField<Content: View>: View {
    let title: String
    let guide: String?
    let isRequired: Bool
    let content: Content

    init(
        _ title: String,
        guide: String? = nil,
        isRequired: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.guide = guide
        self.isRequired = isRequired
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.fieldLabelGap) {
            VStack(alignment: .leading, spacing: 0) {
                FieldTitle(title, isRequired: isRequired)

                if let guide {
                    Text(verbatim: guide)
                        .appFont(AppFont.caption2)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 입력 항목 제목. 필수 항목이면 제목 뒤에 빨간 *를 붙인다.
/// "시간"처럼 컨트롤을 제목 옆에 두는 항목에서도 쓴다.
struct FieldTitle: View {
    let title: String
    let isRequired: Bool

    init(_ title: String, isRequired: Bool = false) {
        self.title = title
        self.isRequired = isRequired
    }

    var body: some View {
        Group {
            if isRequired {
                Text("\(title) \(Text(verbatim: "*").foregroundStyle(AppColor.required))")
            } else {
                Text(verbatim: title)
            }
        }
        .appFont(AppFont.body1)
        .foregroundStyle(AppColor.textPrimary)
        .accessibilityLabel(Text(verbatim: isRequired ? "\(title), 필수" : title))
    }
}

#Preview {
    @Previewable @State var title = ""
    VStack(spacing: AppSpacing.md) {
        FormField("루틴 제목", guide: "5자에서 30자까지 입력해 주세요.", isRequired: true) {
            AppTextField("루틴을 대표하는 제목을 입력해 주세요.", text: $title, maxLength: 30)
        }
        FormField("루틴 소개", guide: "최대 100자까지 입력 가능해요.") {
            AppTextField("나의 루틴을 소개해 주세요.", text: $title, axis: .vertical, maxLength: 100)
        }
    }
    .padding(AppSpacing.md)
}
