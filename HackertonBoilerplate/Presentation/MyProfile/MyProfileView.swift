import HackertonCore
import HackertonMocks
import MVICore
import SwiftUI

struct MyProfileView: View {
    @StateObject private var store: StoreOf<MyProfileReducer>
    @StateObject private var mine: StoreOf<HomeReducer>
    private let session: ProfileSession?
    private let onSwitchAccount: () -> Void
    private let onBack: () -> Void
    @State private var navigationPath: [String] = []
    @State private var feedbackID = UUID()

    init(state: MyProfileReducer.State, onBack: @escaping () -> Void) {
        _store = StateObject(wrappedValue: StoreOf<MyProfileReducer>(state: state, reducer: MyProfileReducer()))
        _mine = StateObject(wrappedValue: StoreOf<HomeReducer>(state: .init(), reducer: HomeReducer()))
        self.onBack = onBack
        session = nil
        onSwitchAccount = {}
    }

    init(session: ProfileSession, onBack: @escaping () -> Void, onSwitchAccount: @escaping () -> Void) {
        _store = StateObject(wrappedValue: StoreOf<MyProfileReducer>(
            state: .init(nickname: session.profile.nickname, introduction: session.profile.bio ?? ""),
            reducer: MyProfileReducer(users: session.repositories.users, images: session.repositories.images)))
        _mine = StateObject(wrappedValue: StoreOf<HomeReducer>(
            state: .init(), reducer: HomeReducer(repository: session.repositories.routines, authorID: session.profile.id)))
        self.session = session
        self.onBack = onBack
        self.onSwitchAccount = onSwitchAccount
    }

    private var visibleRoutines: [HomeReducer.Routine] {
        session == nil ? store.state.visibleRoutines : mine.state.routines
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                AppTopBar("마이", leading: .asset("CaretLeft", label: "뒤로가기", action: onBack))
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        profileHeader
                        HStack(spacing: AppSpacing.sm) {
                            tab(session == nil ? "내 루틴 (\(store.state.myRoutines.count))" : "내 루틴",
                                selection: .mine, id: AccessibilityID.MyProfile.myRoutinesTab)
                            if session == nil {
                                tab("참여 루틴 (\(store.state.participatingRoutines.count))",
                                    selection: .participating, id: AccessibilityID.MyProfile.participatingTab)
                            }
                        }
                        .padding(.vertical, AppSpacing.xs)

                        LazyVStack(spacing: 0) {
                            if mine.state.isLoading && visibleRoutines.isEmpty {
                                ProgressView().padding()
                            } else if let message = mine.state.error {
                                ErrorView(title: "내 루틴을 불러오지 못했어요", message: message, retryTitle: "다시 시도") {
                                    mine.send(.refresh)
                                }
                            } else if visibleRoutines.isEmpty {
                                EmptyView(
                                    title: store.state.selectedTab == .mine ? "작성한 루틴이 없어요" : "참여한 루틴이 없어요",
                                    message: "홈에서 새로운 루틴을 만나보세요."
                                )
                                .padding(.vertical, AppSpacing.md)
                            }
                            ForEach(visibleRoutines) { routine in
                                Button { navigationPath.append(routine.id) } label: {
                                    RoutineListRow(routine: routine, showsParticipation: store.state.selectedTab == .participating)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("myProfile.routine.\(routine.id)")
                                .onAppear { mine.send(.nextPage(routine.id)) }
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
            .background(AppColor.background)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(AccessibilityID.MyProfile.screen)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { id in
                if let session {
                    RoutineDetailDestination(id: id, session: session) { mine.send(.removed(id)) }
                } else if let routine = visibleRoutines.first(where: { $0.id == id }) {
                    RoutineDetailDestination(state: routine.detail)
                }
            }
        }
        .task { mine.send(.appeared) }
        .sheet(isPresented: Binding(
            get: { store.state.edit != nil },
            set: { if !$0 { store.send(.closeEditor) } }
        )) {
            ProfileEditView(store: store, imageURL: session?.profileImageURL)
        }
        .onChange(of: store.state.updatedProfile) { _, profile in
            if let profile, session?.profile.id == profile.id {
                session?.profile = profile
                mine.send(.refresh)
            }
        }
        .feedbackPopup(Binding(
            get: { store.state.notice.map { FeedbackMessage(id: feedbackID, kind: .info, title: "안내", message: $0) } },
            set: { if $0 == nil { store.send(.noticeDismissed) } }
        ))
    }

    private var profileHeader: some View {
        HStack(spacing: 20) {
            if let url = session?.profileImageURL {
                ProfileAvatar(url: url, size: 93)
            } else {
                Image("MyProfileAvatar")
                    .resizable()
                    .frame(width: 93, height: 93)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                    Text(store.state.nickname)
                        .appFont(AppTextStyle(.semiBold, size: 20, relativeTo: .title3))
                    Text(store.state.introduction)
                        .appFont(AppFont.caption1)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(AppColor.grayBlack)
                Button { store.send(.editTapped) } label: {
                    HStack(spacing: AppSpacing.xxs) {
                        Text("프로필 편집").appFont(AppFont.caption2)
                        Image("CaretLeft")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .rotationEffect(.degrees(180))
                    }
                    .foregroundStyle(AppColor.gray500)
                    .contentShape(Rectangle().inset(by: -10))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityID.MyProfile.editButton)
                if session != nil {
                    Button("계정 전환", action: onSwitchAccount)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, AppSpacing.lg)
    }

    private func tab(_ title: String, selection: MyProfileReducer.Tab, id: String) -> some View {
        let isSelected = store.state.selectedTab == selection
        return Button { store.send(.tabSelected(selection)) } label: {
            Text(title)
                .appFont(AppFont.caption1.weight(isSelected ? .semiBold : .medium))
                .foregroundStyle(isSelected ? AppColor.white : AppColor.gray500)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xxs)
                .background(isSelected ? AppColor.primary : AppColor.surface, in: Capsule())
                .contentShape(Rectangle().inset(by: -7))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#if DEBUG
#Preview("마이프로필") {
    MyProfileView(state: MockRoutineData.profile, onBack: {})
}
#endif
