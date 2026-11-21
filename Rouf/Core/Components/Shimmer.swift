import SwiftUI

extension View {
    /// 로딩 중인 스켈레톤 위로 빛이 지나가는 쉬머 애니메이션을 덧씌운다.
    /// 동작 줄이기(Reduce Motion)가 켜져 있으면 애니메이션 없이 스켈레톤만 보인다.
    func shimmer(isActive: Bool = true, duration: Double = 1.2) -> some View {
        modifier(ShimmerModifier(isActive: isActive, duration: duration))
    }
}

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    let duration: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive && reduceMotion == false {
                    ShimmerHighlight(duration: duration)
                        .mask(content)
                        .allowsHitTesting(false)
                }
            }
    }
}

/// 왼쪽 바깥에서 오른쪽 바깥으로 이동하는 하이라이트.
/// 상태를 별도 뷰에 두어 다시 나타날 때마다 처음 위치에서 애니메이션을 시작한다.
private struct ShimmerHighlight: View {
    let duration: Double

    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let bandWidth = proxy.size.width * 0.6
            let travel = proxy.size.width + bandWidth

            LinearGradient(
                colors: [.white.opacity(0), .white.opacity(0.6), .white.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: bandWidth)
            .offset(x: -bandWidth + phase * travel)
        }
        .clipped()
        .onAppear {
            withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        RoundedRectangle(cornerRadius: AppRadius.button)
            .fill(AppColor.gray100)
            .frame(width: 115, height: 115)
            .shimmer()

        RoundedRectangle(cornerRadius: AppRadius.button)
            .fill(AppColor.gray100)
            .frame(height: 187)
            .shimmer()
    }
    .padding(AppSpacing.lg)
}
