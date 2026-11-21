import HackertonCore
import HackertonMocks
import MVICore
import SwiftUI

struct MyProfileView: View {
    @ObservedObject private var store: StoreOf<MyProfileReducer>
    private let onBack: () -> Void
    private let onRoutineSelected: (Int) -> Void
    @State private var feedbackID = UUID()

    init(store: StoreOf<MyProfileReducer>, onRoutineSelected: @escaping (Int) -> Void = { _ in }, onBack: @escaping () -> Void) {
        self.onRoutineSelected = onRoutineSelected
        self.store = store
        self.onBack = onBack
    }

    var body: some View {
        VStack(spacing: 0) {
            AppTopBar("마이", leading: .asset("CaretLeft", label: "홈으로 돌아가기") {
                onBack()
            })
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    profileHeader
                    HStack(spacing: AppSpacing.sm) {
                        tab("내 루틴 (\(store.state.myRoutines.count))", selection: .mine, id: AccessibilityID.MyProfile.myRoutinesTab)
                        tab("참여 루틴 (\(store.state.participatingRoutines.count))", selection: .participating, id: AccessibilityID.MyProfile.participatingTab)
                    }
                    .padding(.vertical, AppSpacing.xs)

                    LazyVStack(spacing: 0) {
                        if store.state.visibleRoutines.isEmpty {
                            EmptyView(
                                title: store.state.selectedTab == .mine ? "작성한 루틴이 없어요" : "참여한 루틴이 없어요",
                                message: "홈에서 새로운 루틴을 만나보세요."
                            )
                            .padding(.vertical, AppSpacing.md)
                        }
                        ForEach(store.state.visibleRoutines) { routine in
                            Button {
                                onRoutineSelected(routine.id)
                            } label: {
                                RoutineListRow(routine: routine, showsParticipation: store.state.selectedTab == .participating)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("myProfile.routine.\(routine.id)")
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
        .background(AppColor.background)
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier(AccessibilityID.MyProfile.screen)
        .feedbackPopup(Binding(
            get: { store.state.notice.map { FeedbackMessage(id: feedbackID, kind: .info, title: "안내", message: $0) } },
            set: { if $0 == nil { store.send(.noticeDismissed) } }
        ))
    }

    private var profileHeader: some View {
        HStack(spacing: 20) {
            Image("MyProfileAvatar")
                .resizable()
                .frame(width: 93, height: 93)
                .accessibilityHidden(true)
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

#Preview("마이프로필") {
    MyProfileView(store: StoreOf<MyProfileReducer>(state: MockRoutineData.profile, reducer: MyProfileReducer()), onBack: {})
}
