import RoufCore
import SwiftUI

/// Figma `time-picker`: 오전/오후, 시(1~12), 분(5분 단위) 휠과 취소·확인 버튼이 있는 바텀시트 내용.
/// 화면에서는 `.timePickerSheet(isPresented:time:)`로 띄운다.
struct TimePickerSheet: View {
    let onCancel: () -> Void
    let onConfirm: (TimeOfDay) -> Void

    @State private var period: TimeOfDay.Period
    @State private var hour12: Int
    @State private var minute: Int

    static let minuteStep = 5

    init(
        time: TimeOfDay,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping (TimeOfDay) -> Void
    ) {
        let time = time.flooringMinute(toMultipleOf: Self.minuteStep)
        self.onCancel = onCancel
        self.onConfirm = onConfirm
        _period = State(initialValue: time.period)
        _hour12 = State(initialValue: time.hour12)
        _minute = State(initialValue: time.minute)
    }

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(verbatim: "시간 선택")
                .font(AppFont.bold(17, relativeTo: .headline))
                .foregroundStyle(AppColor.grayBlack)
                .padding(.top, AppSpacing.lg)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 0) {
                wheel(selection: $period, values: TimeOfDay.Period.allCases, label: "오전 오후") { period in
                    period == .am ? "오전" : "오후"
                }
                .accessibilityIdentifier(AccessibilityID.TimePicker.periodWheel)

                wheel(selection: $hour12, values: Array(1...12), label: "시") { "\($0)" }
                    .accessibilityIdentifier(AccessibilityID.TimePicker.hourWheel)

                wheel(
                    selection: $minute,
                    values: Array(stride(from: 0, to: 60, by: Self.minuteStep)),
                    label: "분"
                ) { String(format: "%02d", $0) }
                    .accessibilityIdentifier(AccessibilityID.TimePicker.minuteWheel)
            }
            .frame(height: Self.wheelHeight)

            HStack(spacing: AppSpacing.xs) {
                PrimaryButton("취소", style: .secondary, action: onCancel)
                    .frame(width: Self.cancelWidth)
                    .accessibilityIdentifier(AccessibilityID.TimePicker.cancelButton)

                PrimaryButton("확인") {
                    onConfirm(TimeOfDay(period: period, hour12: hour12, minute: minute))
                }
                .accessibilityIdentifier(AccessibilityID.TimePicker.confirmButton)
            }
            .padding(.top, AppSpacing.xs)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(AppColor.background)
    }

    private func wheel<Value: Hashable>(
        selection: Binding<Value>,
        values: [Value],
        label: String,
        title: @escaping (Value) -> String
    ) -> some View {
        Picker(selection: selection) {
            ForEach(values, id: \.self) { value in
                Text(verbatim: title(value))
                    .font(AppFont.regular(20, relativeTo: .title3))
                    .foregroundStyle(AppColor.grayBlack)
                    .tag(value)
            }
        } label: {
            Text(verbatim: label)
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private static let wheelHeight: CGFloat = 220
    private static let cancelWidth: CGFloat = 120
    /// Figma 시트 높이.
    static let sheetHeight: CGFloat = 392
}

extension View {
    /// 시간 선택 바텀시트를 띄운다. 확인을 누르면 `time`을 바꾸고 시트를 닫는다.
    func timePickerSheet(isPresented: Binding<Bool>, time: Binding<TimeOfDay>) -> some View {
        sheet(isPresented: isPresented) {
            TimePickerSheet(
                time: time.wrappedValue,
                onCancel: { isPresented.wrappedValue = false },
                onConfirm: { newValue in
                    time.wrappedValue = newValue
                    isPresented.wrappedValue = false
                }
            )
            .presentationDetents([.height(TimePickerSheet.sheetHeight)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(AppRadius.sheet)
            // iOS 26 기본 시트는 반투명 유리 배경이라 Figma처럼 흰 배경으로 채운다.
            .presentationBackground(AppColor.background)
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true
    @Previewable @State var time = TimeOfDay(hour: 10, minute: 30)
    TimeChip(time: time) { isPresented = true }
        .timePickerSheet(isPresented: $isPresented, time: $time)
}
