import RoufCore
import SwiftUI

/// 앱 실행 직후 보이는 스플래시. 캐릭터가 통통 튀어 등장했다가 사라진 뒤 `onFinish`를 호출한다.
/// 화면 상태와 의존성이 없어 Reducer 없이 View만 둔다.
struct SplashView: View {
    /// Figma 스플래시 프레임(402pt 폭)에서 캐릭터가 차지하는 너비.
    private static let characterWidth: CGFloat = 236

    private let isAnimated: Bool
    private let onFinish: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPlaying = false

    /// - Parameter isAnimated: `false`면 캐릭터를 정지 상태로 그리고 `onFinish`를 부르지 않는다. 스냅샷·프리뷰용.
    init(isAnimated: Bool = true, onFinish: @escaping () -> Void = {}) {
        self.isAnimated = isAnimated
        self.onFinish = onFinish
    }

    var body: some View {
        ZStack {
            AppColor.background
                .ignoresSafeArea()
            character
        }
        .accessibilityIdentifier(AccessibilityID.Splash.screen)
        .task { await play() }
    }

    @ViewBuilder
    private var character: some View {
        let image = Image("SplashCharacter")
            .resizable()
            .scaledToFit()
            .frame(width: Self.characterWidth)
            .accessibilityHidden(true)

        if isAnimated == false {
            image
        } else if reduceMotion {
            image
                .opacity(isPlaying ? 1 : 0)
                .animation(.easeIn(duration: 0.3), value: isPlaying)
        } else {
            image.keyframeAnimator(initialValue: CharacterMotion.hidden, trigger: isPlaying) { content, motion in
                content
                    .scaleEffect(x: motion.stretchX, y: motion.stretchY, anchor: .bottom)
                    .offset(y: motion.offsetY)
                    .scaleEffect(motion.scale)
                    .opacity(motion.opacity)
            } keyframes: { _ in
                CharacterMotion.keyframes
            }
        }
    }

    private func play() async {
        guard isAnimated else { return }
        isPlaying = true
        try? await Task.sleep(for: reduceMotion ? CharacterMotion.reducedDuration : CharacterMotion.duration)
        guard Task.isCancelled == false else { return }
        onFinish()
    }
}

/// 캐릭터 등장 모션: 튀어나오기(0~0.5초) → 웅크렸다 점프 후 착지(0.5~1.05초) → 멈춤 → 커지며 사라지기(1.3~1.55초).
private struct CharacterMotion {
    var scale: CGFloat
    var opacity: Double
    var offsetY: CGFloat
    var stretchX: CGFloat
    var stretchY: CGFloat

    static let hidden = CharacterMotion(scale: 0.3, opacity: 0, offsetY: 30, stretchX: 1, stretchY: 1)
    static let duration: Duration = .milliseconds(1550)
    static let reducedDuration: Duration = .milliseconds(900)

    @KeyframesBuilder<CharacterMotion>
    static var keyframes: some Keyframes<CharacterMotion> {
        KeyframeTrack(\.scale) {
            SpringKeyframe(1, duration: 0.5, spring: .bouncy)
            LinearKeyframe(1, duration: 0.8)
            CubicKeyframe(1.12, duration: 0.25)
        }
        KeyframeTrack(\.opacity) {
            LinearKeyframe(1, duration: 0.2)
            LinearKeyframe(1, duration: 1.1)
            LinearKeyframe(0, duration: 0.25)
        }
        KeyframeTrack(\.offsetY) {
            SpringKeyframe(0, duration: 0.5, spring: .bouncy)
            LinearKeyframe(0, duration: 0.12)
            CubicKeyframe(-28, duration: 0.23)
            CubicKeyframe(0, duration: 0.2)
            LinearKeyframe(0, duration: 0.5)
        }
        KeyframeTrack(\.stretchX) {
            LinearKeyframe(1, duration: 0.5)
            CubicKeyframe(1.08, duration: 0.12)
            CubicKeyframe(0.95, duration: 0.23)
            CubicKeyframe(1.06, duration: 0.2)
            SpringKeyframe(1, duration: 0.3, spring: .bouncy)
            LinearKeyframe(1, duration: 0.2)
        }
        KeyframeTrack(\.stretchY) {
            LinearKeyframe(1, duration: 0.5)
            CubicKeyframe(0.9, duration: 0.12)
            CubicKeyframe(1.08, duration: 0.23)
            CubicKeyframe(0.94, duration: 0.2)
            SpringKeyframe(1, duration: 0.3, spring: .bouncy)
            LinearKeyframe(1, duration: 0.2)
        }
    }
}

/// 스플래시가 끝나면 페이드로 걷어내고, 그동안 아래에 미리 그려 둔 콘텐츠를 보여준다.
struct SplashContainer<Content: View>: View {
    @State private var isSplashVisible: Bool
    private let content: Content

    init(showsSplash: Bool, @ViewBuilder content: () -> Content) {
        _isSplashVisible = State(initialValue: showsSplash)
        self.content = content()
    }

    var body: some View {
        ZStack {
            content
                .accessibilityHidden(isSplashVisible)
            if isSplashVisible {
                SplashView {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isSplashVisible = false
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
}

#Preview("애니메이션") {
    SplashContainer(showsSplash: true) {
        RootView()
    }
}

#Preview("정지") {
    SplashView(isAnimated: false)
}
