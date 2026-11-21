import SwiftUI

extension View {
    /// 인스타그램처럼 화면을 오른쪽으로 밀면 왼쪽에서 루틴 만들기 안내가 드러나고,
    /// 충분히 밀거나 빠르게 튕기고 놓으면 화면이 끝까지 밀린 뒤 `onCommit`을 애니메이션 없이 부른다.
    /// 기준선을 넘거나 되돌아올 때 햅틱을 준다.
    func routineCreateSwipe(onCommit: @escaping () -> Void) -> some View {
        modifier(RoutineCreateSwipe(onCommit: onCommit))
    }
}

private struct RoutineCreateSwipe: ViewModifier {
    let onCommit: () -> Void

    /// 드래그 중인 거리. 손을 떼면 `settleAnimation`으로 0이 된다.
    @GestureState(resetTransaction: Transaction(animation: Self.settleAnimation))
    private var drag = DragState()
    /// 손을 뗀 뒤 화면이 머무를 거리. 열기로 했으면 화면 폭까지 같은 애니메이션으로 늘린다.
    /// 드래그 거리가 0으로 줄어드는 동안 같은 곡선으로 늘어나므로 둘의 합은 끊기지 않고 이어진다.
    @State private var settledOffset: CGFloat = 0
    @State private var isCommitting = false
    @State private var width: CGFloat = 0

    private struct DragState {
        var offset: CGFloat = 0
        /// 처음 움직인 방향으로 잠근다. 세로로 시작한 드래그는 스크롤에 맡긴다.
        var isHorizontal: Bool?
    }

    private static let settleAnimation = Animation.spring(duration: 0.32, bounce: 0)
    /// 이 비율만큼 밀고 놓으면 연다.
    private static let commitRatio: CGFloat = 0.35
    /// 덜 밀었어도 놓을 때 예상 이동 거리가 이 비율을 넘으면(빠르게 튕기면) 연다.
    private static let flickRatio: CGFloat = 0.6

    private var offset: CGFloat { settledOffset + drag.offset }
    /// 밀기 시작하면 모서리를 둥글게 키우고, 이 거리만큼 밀면 최대가 된다.
    private static let cornerRoundingDistance: CGFloat = 48
    private var cornerRadius: CGFloat {
        AppRadius.slidingScreen * min(max(offset, 0) / Self.cornerRoundingDistance, 1)
    }
    private var commitDistance: CGFloat { width * Self.commitRatio }
    private var isReady: Bool { width > 0 && drag.offset >= commitDistance }

    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            AppColor.background
                .ignoresSafeArea()

            RoutineCreateSwipeHint(
                progress: commitDistance > 0 ? min(offset / commitDistance, 1) : 0,
                isReady: isReady || isCommitting
            )
            .frame(width: max(offset, 0))
            .frame(maxHeight: .infinity)
            .clipped()
            .accessibilityHidden(true)

            content
                .background(AppColor.background.ignoresSafeArea())
                // 밀리는 동안 홈을 둥근 카드로 보이게 한다. 상태 표시줄·홈 인디케이터 영역까지 같은 모양으로 자른다.
                .mask {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .ignoresSafeArea()
                }
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(AppColor.background)
                        .shadow(color: AppColor.black.opacity(offset > 0 ? AppOpacity.overlay : 0), radius: 24)
                        .ignoresSafeArea()
                }
                .offset(x: offset)
                .allowsHitTesting(!isCommitting)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .simultaneousGesture(dragGesture, isEnabled: !isCommitting)
        .onChange(of: isReady) { _, ready in
            guard !isCommitting else { return }
            HapticFeedbackManager.shared.impact(style: ready ? .medium : .light)
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .updating($drag) { value, state, _ in
                let translation = value.translation
                if state.isHorizontal == nil {
                    state.isHorizontal = abs(translation.width) > abs(translation.height)
                }
                guard state.isHorizontal == true else { return }
                state.offset = min(max(translation.width, 0), width)
            }
            .onEnded { value in
                let translation = value.translation
                guard abs(translation.width) > abs(translation.height), width > 0 else { return }
                let dragged = min(max(translation.width, 0), width)
                let isFlick = value.predictedEndTranslation.width >= width * Self.flickRatio
                guard dragged >= commitDistance || (dragged > 0 && isFlick) else { return }
                commit(fromReady: dragged >= commitDistance)
            }
    }

    private func commit(fromReady: Bool) {
        isCommitting = true
        // 기준선을 넘지 않고 튕겨서 연 경우에는 아직 햅틱이 없었으므로 여기서 준다.
        if !fromReady {
            HapticFeedbackManager.shared.impact(style: .medium)
        }
        withAnimation(Self.settleAnimation) {
            settledOffset = width
        } completion: {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            // 안내 화면과 같은 배경의 전체 화면을 바로 덮은 뒤, 그 뒤에서 홈을 제자리로 돌린다.
            withTransaction(transaction) {
                onCommit()
                settledOffset = 0
                isCommitting = false
            }
        }
    }
}

/// 홈을 오른쪽으로 밀 때 드러나는 루틴 만들기 안내. 드러난 폭의 가운데에 놓인다.
struct RoutineCreateSwipeHint: View {
    /// 기준선까지 민 비율(0...1).
    let progress: CGFloat
    /// 놓으면 열리는 상태.
    let isReady: Bool

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(isReady ? AppColor.white : AppColor.grayBlack)
                .frame(width: Self.iconSize, height: Self.iconSize)
                .background(Circle().fill(isReady ? AppColor.primary : AppColor.surface))
                .scaleEffect(isReady ? 1.08 : 1)

            Text(verbatim: "루틴 만들기")
                .appFont(AppFont.caption1)
                .foregroundStyle(isReady ? AppColor.textPrimary : AppColor.textSecondary)
                .lineLimit(1)
                .fixedSize()
        }
        .opacity(Double(max(min(progress, 1), 0)))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
        .animation(.snappy(duration: 0.2), value: isReady)
    }

    private static let iconSize: CGFloat = 52
}

#Preview {
    HStack(spacing: 0) {
        RoutineCreateSwipeHint(progress: 0.6, isReady: false)
        RoutineCreateSwipeHint(progress: 1, isReady: true)
    }
    .frame(height: 200)
}
