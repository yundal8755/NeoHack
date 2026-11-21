import RoufCore
import SwiftUI

/// 검은 캡슐에 `HH:mm` 시각을 보여주는 버튼. 누르면 시간 선택 시트를 띄우는 데 쓴다.
///
/// ```swift
/// HStack(spacing: AppSpacing.inlineLabelGap) {
///     FieldTitle("시간", isRequired: true)
///     TimeChip(time: time) { isTimePickerPresented = true }
/// }
/// ```
struct TimeChip: View {
    let time: TimeOfDay
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(verbatim: time.formatted)
                .appFont(AppFont.body2.weight(.medium))
                .foregroundStyle(AppColor.white)
                .monospacedDigit()
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xxxs)
                .background(Capsule().fill(AppColor.grayBlack))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: "시간 \(time.formatted)"))
        .accessibilityHint(Text(verbatim: "시간을 선택합니다"))
    }
}

#Preview {
    HStack(spacing: AppSpacing.inlineLabelGap) {
        FieldTitle("시간", isRequired: true)
        TimeChip(time: TimeOfDay(hour: 10, minute: 30)) {}
    }
}
