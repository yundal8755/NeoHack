import HackertonCore
import MVICore
import SwiftUI

struct HomeView: View {
    @ObservedObject private var store: StoreOf<HomeReducer>
    private let onRefresh: () async -> Void
    @State private var isPickingRoutineImages = false
    @State private var isProfilePresented = false

    init(store: StoreOf<HomeReducer>, onRefresh: @escaping () async -> Void = {}) {
        self.store = store
        self.onRefresh = onRefresh
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppTopBar("서비스명", trailing: .asset("User", label: "마이프로필") {
                    isProfilePresented = true
                })

                sortPicker

                routineList
            }
            .background(AppColor.background)
            .overlay(alignment: .bottomTrailing) {
                Button { isPickingRoutineImages = true } label: {
                    Image("HomeCreateButton")
                        .frame(width: 55, height: 55)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("루틴 만들기")
                .accessibilityIdentifier(AccessibilityID.Home.createButton)
                .padding(AppSpacing.md)
            }
            .routineCreateSwipe(onProfile: { isProfilePresented = true }) {
                isPickingRoutineImages = true
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Int.self) { id in
                if let routine = store.state.routines.first(where: { $0.id == id }) {
                    HomeRoutineDetailDestination(state: routine.detail)
                }
            }
            .navigationDestination(isPresented: $isProfilePresented) {
                // shortcut: 프로필 프레임이 아직 없어 진입 화면만 제공한다. 디자인 전달 후 MyProfileView로 교체한다.
                VStack(spacing: 0) {
                    AppTopBar("마이프로필", leading: .asset("CaretLeft", label: "뒤로가기") {
                        isProfilePresented = false
                    })
                    EmptyView(title: "마이프로필", message: "프로필 화면을 준비하고 있어요.", systemImage: "person")
                        .padding(AppSpacing.md)
                    Spacer()
                }
                .background(AppColor.background)
                .toolbar(.hidden, for: .navigationBar)
            }
        }
        .routineCreateFlow(isPickingImages: $isPickingRoutineImages)
        .accessibilityIdentifier(AccessibilityID.Root.homeScreen)
    }

    private var sortPicker: some View {
                HStack {
                    Spacer()
                    Menu {
                        Picker("루틴 정렬", selection: Binding(
                            get: { store.state.sort },
                            set: { store.send(.sortChanged($0)) }
                        )) {
                            ForEach(HomeReducer.Sort.allCases, id: \.self) { sort in
                                Text(sort.rawValue).tag(sort)
                            }
                        }
                    } label: {
                        HStack(spacing: AppSpacing.xxs) {
                            Text(store.state.sort.rawValue)
                                .appFont(AppFont.caption1.weight(.medium))
                            Image("CaretLeft")
                                .resizable()
                                .frame(width: 18, height: 18)
                                .rotationEffect(.degrees(-90))
                        }
                        .foregroundStyle(AppColor.gray600)
                        .padding(.horizontal, 11)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(AppColor.surface, in: Capsule())
                        .frame(minHeight: 44)
                    }
                    .accessibilityIdentifier(AccessibilityID.Home.sortButton)
                }
                .padding(.horizontal, AppSpacing.md)

    }

    private var routineList: some View {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if store.state.routines.isEmpty {
                            EmptyView(title: "아직 루틴이 없어요", message: "+ 버튼을 눌러 나만의 루틴을 만들어보세요.")
                                .padding(.top, AppSpacing.lg)
                        }
                        ForEach(store.state.sortedRoutines) { routine in
                            NavigationLink(value: routine.id) {
                                routineRow(routine)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier(AccessibilityID.Home.routine(routine.id))
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, 88)
                }
                .refreshable { await onRefresh() }
                .scrollBounceBehavior(.always)
    }

    private func routineRow(_ routine: HomeReducer.Routine) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: AppSpacing.xs) {
                        Image("RoutineDetailAvatar")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .accessibilityHidden(true)
                        Text(routine.nickname)
                            .appFont(AppFont.body2)
                            .foregroundStyle(AppColor.grayBlack)
                    }
                    .padding(.vertical, AppSpacing.xxs)

                    Text(routine.detail.title)
                        .appFont(AppFont.body1)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(2)
                        .padding(.vertical, AppSpacing.xxxs)
                    Text(routine.introduction)
                        .appFont(AppFont.caption1)
                        .foregroundStyle(AppColor.gray600)
                        .lineLimit(2)
                        .padding(.vertical, AppSpacing.xxxs)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Group {
                    if let url = routine.detail.steps.first?.imageURL {
                        NetworkImageView(
                            url: url,
                            cornerRadius: AppRadius.button,
                            downsamplingSize: CGSize(width: 115, height: 115),
                            accessibilityLabel: "루틴 대표 이미지",
                            borderColor: nil,
                            showsLoadingText: false
                        )
                    } else {
                        RoundedRectangle(cornerRadius: AppRadius.button).fill(AppColor.gray400)
                    }
                }
                .frame(width: 115, height: 115)
            }
            HStack(spacing: AppSpacing.buttonPadding) {
                count("Heart", value: routine.detail.likeCount)
                count("ChatCircle", value: routine.detail.commentCount)
            }
            .padding(.vertical, AppSpacing.xxs)
        }
        .padding(.vertical, AppSpacing.md)
        .contentShape(Rectangle())
    }

    private func count(_ asset: String, value: Int) -> some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(asset).frame(width: 24, height: 24)
            Text("\(value)").appFont(AppFont.caption1)
        }
        .foregroundStyle(AppColor.gray800)
    }
}

private struct HomeRoutineDetailDestination: View {
    @StateObject private var store: StoreOf<RoutineDetailReducer>

    init(state: RoutineDetailReducer.State) {
        _store = StateObject(wrappedValue: StoreOf<RoutineDetailReducer>(state: state, reducer: RoutineDetailReducer()))
    }

    var body: some View { RoutineDetailView(store: store) }
}

enum HomePreview {
    static var state: HomeReducer.State {
        let titles: [String] = ["김햄찌의 하루", "느긋한 주말 아침", "퇴근 후 작은 산책", "오늘은 집밥", "책과 함께하는 밤", "출근길 새로운 발견", "방 정리하는 오후", "친구와 동네 한 바퀴", "하루 한 곡 집중하기", "나만의 카페 시간", "잠들기 전 스트레칭", "일요일 저녁 기록"]
        let names: [String] = ["김햄찌", "느림보", "산책러", "집밥요정", "책갈피", "발견왕"]
        let routines: [HomeReducer.Routine] = titles.indices.map { index -> HomeReducer.Routine in
            var detail = RoutineDetailPreview.state
            detail.title = titles[index]
            detail.likeCount = 10 + (index * 7) % 31
            detail.commentCount = 2 + index
            detail.participatingCount = index % 5
            detail.completedCount = index * 2
            return HomeReducer.Routine(
                id: index,
                nickname: names[index % names.count],
                introduction: index == 0 ? "제 찐 일상인데요... 딱히 재밌는 건 없네요" : "익숙한 하루를 조금 다르게 보내는 나만의 루틴이에요.",
                createdAt: Date(timeIntervalSince1970: Double(12 - index)),
                detail: detail
            )
        }
        return HomeReducer.State(routines: routines)
    }
}

#Preview("홈") {
    HomeView(store: StoreOf<HomeReducer>(state: HomePreview.state, reducer: HomeReducer()))
}
