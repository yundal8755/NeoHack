import HackertonCore
import MVICore
import SwiftUI

/// Figma `온보딩` 프레임 3장. 캐릭터, 제목, 설명을 페이지로 넘기고 하단 다음 버튼으로 진행한다.
/// 마지막 페이지에서 다음을 누르면 `onFinish`를 호출한다.
struct OnboardingView: View {
    typealias Feature = OnboardingReducer

    /// Figma 온보딩 페이지 문구와 그래픽. 그래픽이 없는 페이지도 같은 자리를 비워 문구 위치를 맞춘다.
    struct Page: Equatable {
        let image: Illustration?
        let title: String
        let message: String

        /// 그래픽 에셋 이름과 Figma 프레임(402pt 폭)에서 차지하는 크기.
        /// - `bleed`: 에셋 가장자리에 둔 여백. 그래픽이 잘리지 않게 여백을 두되 배치는 `size` 기준으로 한다.
        /// - `offsetY`: 그래픽 자리 아래쪽에 붙인 위치에서 아래로 내리는 정도. 자리보다 큰 그래픽을 Figma 위치에 맞출 때 쓴다.
        struct Illustration: Equatable {
            let name: String
            let size: CGSize
            var bleed: CGFloat = 0
            var offsetY: CGFloat = 0
        }

        static let all: [Page] = [
            Page(
                // 눈을 반쯤 감은 캐릭터. Figma에서 캐릭터 아래가 그래픽 자리 아래보다 19pt 위에 있다.
                image: Illustration(
                    name: "OnboardingSleepyCharacter",
                    size: CGSize(width: 250, height: 186),
                    offsetY: -19
                ),
                title: "이동 시간, 오늘도 멍하셨나요?",
                message: "매일 똑같은 길이 지루하죠"
            ),
            Page(
                // 루틴 상세 화면을 담은 휴대폰 목업. 아래쪽은 흰색으로 흐려지며 제목 위까지 내려온다.
                image: Illustration(
                    name: "OnboardingRoutinePreview",
                    size: CGSize(width: 217, height: 363),
                    offsetY: 38
                ),
                title: "사소한 순간이 특별한 루틴으로",
                message: "반복되던 일상을 루틴으로 만들어요"
            ),
            Page(
                image: Illustration(name: "OnboardingTogether", size: CGSize(width: 297, height: 254), bleed: 12),
                title: "혼자 말고 함께 해요!",
                message: "서로의 루틴을 따라 하고 응원해요"
            ),
        ]
    }

    /// 그래픽 자리 높이. 가장 큰 그래픽(세 번째 페이지 구름 둘)에 맞추고, 작은 그래픽은 아래쪽에 붙인다.
    private static let illustrationHeight: CGFloat = 254
    /// 그래픽 자리 아래와 제목 사이.
    private static let illustrationTitleGap: CGFloat = 73
    /// 그래픽·문구 묶음을 화면 가운데보다 아래로 내리는 정도.
    /// 상단 안전 영역과 관계없이 프레임 맨 위 기준으로 잰다.
    /// Figma 874pt 프레임에서 그래픽 자리 위 231pt, 설명 아래 157pt가 남도록 한 값이고, 작은 화면에서는 위아래 여백이 함께 줄어든다.
    private static let contentTopInset: CGFloat = 73

    @StateObject private var store: StoreOf<Feature>
    @State private var safeAreaTop: CGFloat = 0
    private let pages: [Page]
    private let onFinish: () -> Void

    init(store: StoreOf<Feature>, pages: [Page] = Page.all, onFinish: @escaping () -> Void = {}) {
        _store = StateObject(wrappedValue: store)
        self.pages = pages
        self.onFinish = onFinish
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                        .accessibilityIdentifier(AccessibilityID.Onboarding.page(index))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            PrimaryButton("다음") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    store.send(.nextTapped)
                }
            }
            .accessibilityHint(store.state.isLastPage ? "온보딩을 마치고 시작해요" : "다음 소개로 넘어가요")
            .accessibilityIdentifier(AccessibilityID.Onboarding.nextButton)
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.xs)
        }
        .background(AppColor.background.ignoresSafeArea())
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { safeAreaTop = $0 }
        .accessibilityIdentifier(AccessibilityID.Onboarding.screen)
        .onChange(of: store.state.isFinished) { _, isFinished in
            if isFinished { onFinish() }
        }
    }

    private var currentPage: Binding<Int> {
        Binding(
            get: { store.state.currentPage },
            set: { store.send(.pageChanged($0)) }
        )
    }

    private func pageView(_ page: Page) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            illustration(page.image)
                .padding(.bottom, Self.illustrationTitleGap)
            VStack(spacing: AppSpacing.md) {
                Text(verbatim: page.title)
                    .appFont(AppFont.title1)
                    .foregroundStyle(AppColor.textPrimary)
                Text(verbatim: page.message)
                    .appFont(AppFont.caption1)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)
        }
        // 페이지는 상단 안전 영역 아래부터 그려지므로, 그만큼 빼서 프레임 맨 위 기준 위치를 맞춘다.
        .padding(.top, max(Self.contentTopInset - safeAreaTop, 0))
        .padding(.horizontal, AppSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func illustration(_ image: Page.Illustration?) -> some View {
        ZStack(alignment: .bottom) {
            Color.clear
            if let image {
                Image(image.name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: image.size.width + image.bleed * 2, height: image.size.height + image.bleed * 2)
                    .padding(-image.bleed)
                    .offset(y: image.offsetY)
            }
        }
        .frame(height: Self.illustrationHeight, alignment: .bottom)
        .accessibilityHidden(true)
    }
}

/// 첫 실행에만 온보딩을 띄우고, 마치면 기록을 남긴 뒤 아래에 미리 그려 둔 콘텐츠를 보여준다.
struct OnboardingContainer<Content: View>: View {
    static var completedKey: String { "hasCompletedOnboarding" }

    @AppStorage(Self.completedKey) private var hasCompleted = false
    @State private var store = StoreOf<OnboardingReducer>(
        state: .init(pageCount: OnboardingView.Page.all.count),
        reducer: OnboardingReducer()
    )
    private let isEnabled: Bool
    private let content: Content

    init(isEnabled: Bool, @ViewBuilder content: () -> Content) {
        self.isEnabled = isEnabled
        self.content = content()
    }

    private var showsOnboarding: Bool {
        isEnabled && !hasCompleted
    }

    var body: some View {
        ZStack {
            content
                .accessibilityHidden(showsOnboarding)
            if showsOnboarding {
                OnboardingView(store: store) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        hasCompleted = true
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
}

#Preview("온보딩") {
    OnboardingView(store: StoreOf<OnboardingReducer>(
        state: .init(pageCount: OnboardingView.Page.all.count),
        reducer: OnboardingReducer()
    ))
}
