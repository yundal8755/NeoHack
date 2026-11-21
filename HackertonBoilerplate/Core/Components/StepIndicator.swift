import SwiftUI

/// Figma `단계` 컴포넌트를 나열한 단계 인디케이터.
/// `current`까지(지나온 단계와 현재 단계)는 Primary 원, 나머지는 회색 원으로 그린다.
/// 마지막 단계 다음 화면(루틴 소개)에서는 `current`를 `count`보다 크게 주면 모두 Primary가 된다.
struct StepIndicator: View {
    let count: Int
    let current: Int

    /// - Parameters:
    ///   - count: 전체 단계 수.
    ///   - current: 현재 단계(1부터 시작).
    init(count: Int, current: Int) {
        self.count = max(count, 0)
        self.current = current
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ForEach(0..<count, id: \.self) { index in
                StepBadge(number: index + 1, isActive: index + 1 <= current)
            }
        }
        .padding(.vertical, AppSpacing.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(count)단계 중 \(min(current, count))단계"))
    }
}

/// 단계 번호 원 하나. Figma `단계`의 Default(회색)·Variant2(Primary) 변형.
struct StepBadge: View {
    let number: Int
    let isActive: Bool

    var body: some View {
        Text(verbatim: "\(number)")
            .font(isActive ? AppFont.caption2.weight(.medium).font : AppFont.caption2.font)
            .foregroundStyle(isActive ? AppColor.white : AppColor.gray500)
            .frame(width: Self.size, height: Self.size)
            .background(Circle().fill(isActive ? AppColor.primary : AppColor.gray200))
    }

    private static let size: CGFloat = 24
}

#Preview {
    VStack {
        StepIndicator(count: 4, current: 1)
        StepIndicator(count: 4, current: 2)
        StepIndicator(count: 4, current: 5)
    }
}
