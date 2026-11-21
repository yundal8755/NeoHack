import HackertonCore
import MVICore
import SwiftUI

struct HomeView: View {
    @ObservedObject private var store: StoreOf<HomeReducer>
    private let onRefresh: () async -> Void
    @StateObject private var profileStore = StoreOf<MyProfileReducer>(state: MockRoutineData.profile, reducer: MyProfileReducer())
    @State private var isPickingRoutineImages = false
    @State private var navigationPath: [Int] = []
    @State private var isHomeDragging = false
    @State private var isSortExpanded = false
    @State private var isProfilePresented = false

    init(store: StoreOf<HomeReducer>, session: ProfileSession? = nil, onSwitchAccount: @escaping () -> Void = {}) {
        self.store = store
        self.session = session
        self.onSwitchAccount = onSwitchAccount
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
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
            .routineCreateSwipe(profile: profileView, isProfilePresented: $isProfilePresented, isDragging: $isHomeDragging) {
                isPickingRoutineImages = true
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Int.self) { id in
                if let routine = store.state.routines.first(where: { $0.id == id }) {
                    RoutineDetailDestination(state: routine.detail)
                }
            }
        }
        .onChange(of: isProfilePresented) { _, presented in
            if presented { navigationPath.removeAll() }
        }
        .task { store.send(.appeared) }
        .routineCreateFlow(isPickingImages: $isPickingRoutineImages, repositories: session?.repositories) { id in
            store.send(.refresh)
            path.append(id)
        }
        .accessibilityIdentifier(AccessibilityID.Root.homeScreen)
    }

    private var profileView: some View {
        MyProfileView(store: profileStore) { isProfilePresented = false }
    }

    private var sortPicker: some View {
        HStack {
            Spacer()
            Button {
                isSortExpanded.toggle()
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Text(store.state.sort.rawValue)
                        .appFont(AppFont.caption1.weight(.medium))
                    Image("CaretLeft")
                        .resizable()
                        .frame(width: 18, height: 18)
                        .rotationEffect(.degrees(isSortExpanded ? 90 : -90))
                }
                .foregroundStyle(AppColor.gray500)
                .padding(.horizontal, 11)
                .padding(.vertical, AppSpacing.xxs)
                .background(AppColor.background)
                .overlay {
                    RoundedRectangle(cornerRadius: 3).strokeBorder(AppColor.gray200)
                }
                .frame(minHeight: 37)
                .contentShape(Rectangle().inset(by: -4))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("정렬: \(store.state.sort.rawValue)")
            .accessibilityValue(isSortExpanded ? "펼쳐짐" : "접힘")
            .accessibilityIdentifier(AccessibilityID.Home.sortButton)
        }
        .padding(.horizontal, AppSpacing.md)
        .overlay(alignment: .topTrailing) {
            if isSortExpanded {
                VStack(spacing: AppSpacing.xxxs) {
                    ForEach(HomeReducer.Sort.allCases, id: \.self) { sort in
                        Button {
                            store.send(.sortChanged(sort))
                            isSortExpanded = false
                        } label: {
                            Text(sort.rawValue)
                                .appFont(AppFont.caption1)
                                .foregroundStyle(AppColor.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, AppSpacing.buttonPadding)
                                .padding(.vertical, AppSpacing.xxs)
                                .background(store.state.sort == sort ? AppColor.surface : AppColor.background)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(store.state.sort == sort ? .isSelected : [])
                    }
                }
                .padding(AppSpacing.xxs)
                .frame(width: 86)
                .background(AppColor.background)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .shadow(color: AppColor.black.opacity(0.08), radius: 4, y: 2)
                .padding(.trailing, AppSpacing.md)
                .offset(y: 40)
            }
        }
        .zIndex(1)
    }

    private var routineList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if store.state.routines.isEmpty {
                    EmptyView(title: "아직 루틴이 없어요", message: "+ 버튼을 눌러 나만의 루틴을 만들어보세요.")
                        .padding(.top, AppSpacing.lg)
                }
                ForEach(store.state.sortedRoutines) { routine in
                    Button {
                        guard !isHomeDragging, !isProfilePresented, !isPickingRoutineImages else { return }
                        navigationPath.append(routine.id)
                    } label: {
                        RoutineListRow(routine: routine)
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


}

#if DEBUG
#Preview {
    HomeView(store: StoreOf<HomeReducer>(state: MockRoutineData.home, reducer: HomeReducer()))
}
#endif
