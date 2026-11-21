import SwiftUI

extension View {
    /// 인스타그램처럼 화면을 오른쪽으로 밀면 왼쪽에서 루틴 만들기 안내가 드러나고,
    /// 충분히 밀거나 빠르게 튕기고 놓으면 화면이 끝까지 밀린 뒤 `onCommit`을 애니메이션 없이 부른다.
    /// 왼쪽으로 밀면 뒤에 있던 프로필이 드러나고, 프로필에서 오른쪽으로 밀면 같은 방식으로 홈을 다시 끌어온다.
    /// 기준선을 넘거나 되돌아올 때 햅틱을 준다.
    func routineCreateSwipe<Profile: View>(profile: Profile, isProfilePresented: Binding<Bool>, isDragging: Binding<Bool>, onCommit: @escaping () -> Void) -> some View {
        modifier(RoutineCreateSwipe(profile: profile, isProfilePresented: isProfilePresented, isDragging: isDragging, onCommit: onCommit))
    }
}

private struct RoutineCreateSwipe<Profile: View>: ViewModifier {
    let profile: Profile
    @Binding var isProfilePresented: Bool
    @Binding var isDragging: Bool
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

    private static var settleAnimation: Animation { .spring(duration: 0.32, bounce: 0) }
    /// 이 비율만큼 밀고 놓으면 연다.
    private static var commitRatio: CGFloat { 0.35 }
    /// 덜 밀었어도 놓을 때 예상 이동 거리가 이 비율을 넘으면(빠르게 튕기면) 연다.
    private static var flickRatio: CGFloat { 0.6 }

    private var offset: CGFloat { settledOffset + drag.offset }
    private var commitDistance: CGFloat { width * Self.commitRatio }
    private var isReady: Bool { width > 0 && abs(drag.offset) >= commitDistance }

    func body(content: Content) -> some View {
        ZStack(alignment: offset < 0 ? .trailing : .leading) {
            AppColor.background
                .ignoresSafeArea()

            profile
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(isProfilePresented)
                .accessibilityHidden(!isProfilePresented)

            if offset >= 0 {
                RoutineCreateSwipeHint(
                    progress: commitDistance > 0 ? min(offset / commitDistance, 1) : 0,
                    isReady: isReady || isCommitting
                )
                .frame(width: max(offset, 0))
                .frame(maxHeight: .infinity)
                .clipped()
                .accessibilityHidden(true)
            }

            content
                .modifier(SlidingCard(offset: offset, width: width))
                // 가로 드래그 중 카드 버튼이 손을 떼는 동작을 탭으로 처리하지 않게 한다.
                .allowsHitTesting(!isProfilePresented && !isCommitting && drag.isHorizontal != true)
                .accessibilityHidden(isProfilePresented)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: {
            width = $0
            if isProfilePresented { settledOffset = -width }
        }
        .onChange(of: isProfilePresented) { _, presented in
            withAnimation(Self.settleAnimation) {
                settledOffset = presented ? -width : 0
            }
        }
        .simultaneousGesture(dragGesture, isEnabled: !isCommitting)
        .onChange(of: drag.isHorizontal) { _, isHorizontal in
            // 화면을 넘기지 않고 끝났거나 시스템 제스처에 끊긴 드래그를 정리한다. 넘기는 중이면 `commit`이 끝나면서 푼다.
            if isHorizontal == nil, !isCommitting { endDragging() }
        }
        .onChange(of: isReady) { _, ready in
            guard !isCommitting else { return }
            HapticFeedbackManager.shared.impact(style: ready ? .medium : .light)
        }
    }

    /// 드래그로 움직일 수 있는 거리. 프로필이 열려 있으면 왼쪽 밖에 있는 홈을 제자리까지만 끌어온다.
    private func clamped(_ translation: CGFloat) -> CGFloat {
        min(max(translation, isProfilePresented ? 0 : -width), width)
    }

    /// 홈에서 양쪽으로 밀 때와 프로필에서 홈을 끌어올 때 모두 이 제스처 하나로 처리한다.
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .updating($drag) { value, state, _ in
                let translation = value.translation
                if state.isHorizontal == nil {
                    state.isHorizontal = abs(translation.width) > abs(translation.height)
                }
                guard state.isHorizontal == true else { return }
                state.offset = clamped(translation.width)
            }
            .onChanged { _ in
                if drag.isHorizontal == true {
                    isDragging = true
                }
            }
            .onEnded { value in
                let translation = value.translation
                guard abs(translation.width) > abs(translation.height), width > 0 else { return }
                let dragged = clamped(translation.width)
                let direction: CGFloat = dragged < 0 ? -1 : 1
                let isFlick = value.predictedEndTranslation.width * direction >= width * Self.flickRatio
                let fromReady = abs(dragged) >= commitDistance
                guard fromReady || (abs(dragged) > 0 && isFlick) else { return }
                if isProfilePresented {
                    returnHome(fromReady: fromReady)
                } else {
                    commit(direction: direction, fromReady: fromReady)
                }
            }
    }

    /// 프로필에서 홈을 끌어와 놓았을 때. 홈이 맨 위 카드라 덮을 화면이 없으므로 바로 닫힌 상태로 바꾸고,
    /// 놓은 자리에서 제자리까지는 열 때와 같은 `settleAnimation`으로 이어서 움직인다.
    private func returnHome(fromReady: Bool) {
        if !fromReady {
            HapticFeedbackManager.shared.impact(style: .medium)
        }
        withAnimation(Self.settleAnimation) {
            settledOffset = 0
        }
        isProfilePresented = false
    }

    /// 드래그가 끝났을 때 `isDragging`을 푼다.
    /// 카드 버튼은 손을 뗄 때 이 제스처의 `onEnded`보다 늦게 탭을 처리하므로, 그 탭이 지나간 다음에 풀리도록 한 박자 늦춘다.
    private func endDragging() {
        let isDragging = $isDragging
        DispatchQueue.main.async { isDragging.wrappedValue = false }
    }

    private func commit(direction: CGFloat, fromReady: Bool) {
        isCommitting = true
        // 기준선을 넘지 않고 튕겨서 연 경우에는 아직 햅틱이 없었으므로 여기서 준다.
        if !fromReady {
            HapticFeedbackManager.shared.impact(style: .medium)
        }
        withAnimation(Self.settleAnimation) {
            settledOffset = width * direction
        } completion: {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            // 안내 화면과 같은 배경의 전체 화면을 바로 덮은 뒤, 그 뒤에서 홈을 제자리로 돌린다.
            withTransaction(transaction) {
                if direction < 0 {
                    // 뒤에 드러난 프로필을 그대로 유지한다. NavigationStack으로 다시 push하지 않는다.
                    isProfilePresented = true
                    settledOffset = -width
                } else {
                    onCommit()
                    settledOffset = 0
                }
                isCommitting = false
                isDragging = false
            }
        }
    }
}

/// 밀리는 홈 카드의 모양. 모서리와 그림자를 지금 위치에서 바로 계산하므로,
/// 손으로 끌든 버튼으로 열고 닫든 같은 위치에서는 같은 모습으로 지나간다.
private struct SlidingCard: ViewModifier, Animatable {
    /// 제자리에서 밀린 거리. 애니메이션 중에는 그 순간의 중간 값이 들어온다.
    var offset: CGFloat
    let width: CGFloat

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    /// 밀기 시작하면 모서리를 둥글게 키우고, 이 거리만큼 밀면 최대가 된다.
    private static var roundingDistance: CGFloat { 48 }

    private var cornerRadius: CGFloat {
        AppRadius.slidingScreen * min(abs(offset) / Self.roundingDistance, 1)
    }

    /// 화면 밖으로 다 나간 카드의 그림자가 가장자리에 남지 않게, 다 나가기 직전부터 옅어진다.
    private var shadowOpacity: Double {
        guard abs(offset) > 0 else { return 0 }
        let remaining = max(width - abs(offset), 0)
        return AppOpacity.overlay * Double(min(remaining / Self.roundingDistance, 1))
    }

    func body(content: Content) -> some View {
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
                    .shadow(color: AppColor.black.opacity(shadowOpacity), radius: 24)
                    .ignoresSafeArea()
            }
            .offset(x: offset)
    }
}

/// 홈을 오른쪽으로 밀 때 드러나는 루틴 만들기 안내. 드러난 폭의 가운데에 놓인다.
struct RoutineCreateSwipeHint: View {
    /// 기준선까지 민 비율(0...1).
    let progress: CGFloat
    /// 놓으면 열리는 상태.
    let isReady: Bool
    var title: String = "루틴 만들기"
    var systemImage: String = "plus"

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(isReady ? AppColor.white : AppColor.grayBlack)
                .frame(width: Self.iconSize, height: Self.iconSize)
                .background(Circle().fill(isReady ? AppColor.primary : AppColor.surface))
                .scaleEffect(isReady ? 1.08 : 1)

            Text(verbatim: title)
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
