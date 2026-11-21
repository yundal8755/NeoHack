import HackertonCore
import HackertonMocks
import MVICore
import SwiftUI

struct MyProfileView: View {
    @StateObject private var store: StoreOf<MyProfileReducer>
    @StateObject private var participating: StoreOf<HomeReducer>
    private let participationCompletedID: UUID?
    private let routineUpdatedID: UUID?
    @StateObject private var mine: StoreOf<HomeReducer>
    private let session: ProfileSession?
    private let onBack: () -> Void
    private let onRoutineSelected: (HomeReducer.Routine) -> Void
    private let deletedRoutineID: String?
    @State private var feedbackID = UUID()

    init(
        state: MyProfileReducer.State, onRoutineSelected: @escaping (HomeReducer.Routine) -> Void = { _ in },
        onBack: @escaping () -> Void
    ) {
        _store = StateObject(wrappedValue: StoreOf<MyProfileReducer>(state: state, reducer: MyProfileReducer()))
        _mine = StateObject(wrappedValue: StoreOf<HomeReducer>(state: .init(), reducer: HomeReducer()))
        self.onBack = onBack
        self.onRoutineSelected = onRoutineSelected
        deletedRoutineID = nil
        participationCompletedID = nil
        routineUpdatedID = nil
        _participating = StateObject(wrappedValue: StoreOf<HomeReducer>(state: .init(), reducer: HomeReducer()))
        session = nil
    }

    init(
        session: ProfileSession, deletedRoutineID: String?, participationCompletedID: UUID? = nil,
        routineUpdatedID: UUID? = nil,
        onRoutineSelected: @escaping (HomeReducer.Routine) -> Void, onBack: @escaping () -> Void
    ) {
        _store = StateObject(
            wrappedValue: StoreOf<MyProfileReducer>(
                state: .init(nickname: session.profile.nickname, introduction: session.profile.bio ?? ""),
                reducer: MyProfileReducer(users: session.repositories.users, images: session.repositories.images)))
        _mine = StateObject(
            wrappedValue: StoreOf<HomeReducer>(
                state: .init(),
                reducer: HomeReducer(repository: session.repositories.routines, authorID: session.profile.id)))
        _participating = StateObject(wrappedValue: StoreOf<HomeReducer>(
            state: .init(), reducer: HomeReducer(repository: session.repositories.routines, participantID: session.profile.id)))
        self.participationCompletedID = participationCompletedID
        self.routineUpdatedID = routineUpdatedID
        self.session = session
        self.deletedRoutineID = deletedRoutineID
        self.onRoutineSelected = onRoutineSelected
        self.onBack = onBack
    }

    private var visibleRoutines: [HomeReducer.Routine] {
        session == nil ? store.state.visibleRoutines : activeList.state.routines
    }

    private var activeList: StoreOf<HomeReducer> {
        store.state.selectedTab == .mine ? mine : participating
    }

    var body: some View {
        VStack(spacing: 0) {
            AppTopBar("마이", leading: .asset("CaretLeft", label: "홈으로 돌아가기", action: onBack))
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    profileHeader
                    HStack(spacing: AppSpacing.sm) {
                        tab(
                            session == nil ? "내 루틴 (\(store.state.myRoutines.count))" : tabTitle("내 루틴", count: mine.state.totalCount),
                            selection: .mine, id: AccessibilityID.MyProfile.myRoutinesTab)
                        tab(
                            session == nil ? "참여 루틴 (\(store.state.participatingRoutines.count))" : tabTitle("참여 루틴", count: participating.state.totalCount),
                            selection: .participating, id: AccessibilityID.MyProfile.participatingTab)
                    }
                    .padding(.vertical, AppSpacing.xs)

                    LazyVStack(spacing: 0) {
                        if activeList.state.isLoading && visibleRoutines.isEmpty {
                            ProgressView().padding()
                        } else if let message = activeList.state.error {
                            ErrorView(title: "루틴을 불러오지 못했어요", message: message, retryTitle: "다시 시도") {
                                activeList.send(.refresh)
                            }
                        } else if visibleRoutines.isEmpty {
                            EmptyView(
                                title: store.state.selectedTab == .mine ? "작성한 루틴이 없어요" : "참여한 루틴이 없어요",
                                message: "홈에서 새로운 루틴을 만나보세요."
                            )
                            .padding(.vertical, AppSpacing.md)
                        }
                        ForEach(visibleRoutines) { routine in
                            Button {
                                onRoutineSelected(routine)
                            } label: {
                                RoutineListRow(
                                    routine: routine, showsParticipation: store.state.selectedTab == .participating)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("myProfile.routine.\(routine.id)")
                            .onAppear { activeList.send(.nextPage(routine.id)) }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
        .refreshable {
            activeList.send(.refresh)
            while activeList.state.isLoading && !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
        .background(AppColor.background)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.MyProfile.screen)
        .toolbar(.hidden, for: .navigationBar)
        .task(id: participationCompletedID) {
            mine.send(.appeared)
            if participationCompletedID != nil {
                store.send(.tabSelected(.participating))
                participating.send(.refresh)
            } else {
                participating.send(.appeared)
            }
        }
        .onChange(of: routineUpdatedID) { _, _ in
            mine.send(.refresh)
            participating.send(.refresh)
        }
        .onChange(of: deletedRoutineID) { _, id in
            if let id { mine.send(.removed(id)) }
        }
        .navigationDestination(
            isPresented: Binding(
                get: { store.state.edit != nil },
                set: { if !$0 { store.send(.editorDismissed) } }
            )
        ) {
            ProfileEditView(store: store, imageURL: session?.profileImageURL)
        }
        .onChange(of: store.state.updatedProfile) { _, profile in
            if let profile, session?.profile.id == profile.id {
                session?.profile = profile
                mine.send(.refresh)
            }
        }
        .feedbackPopup(
            Binding(
                get: {
                    store.state.notice.map { FeedbackMessage(id: feedbackID, kind: .info, title: "안내", message: $0) }
                },
                set: { if $0 == nil { store.send(.noticeDismissed) } }
            ),
            presentation: .topToast
        )
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
                Button {
                    store.send(.editTapped)
                } label: {
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, AppSpacing.lg)
    }

    private func tabTitle(_ title: String, count: Int?) -> String {
        count.map { "\(title) (\($0))" } ?? title
    }

    private func tab(_ title: String, selection: MyProfileReducer.Tab, id: String) -> some View {
        let isSelected = store.state.selectedTab == selection
        return Button {
            store.send(.tabSelected(selection))
        } label: {
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
