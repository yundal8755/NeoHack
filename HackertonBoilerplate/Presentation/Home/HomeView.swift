import HackertonCore
import MVICore
import SwiftUI

struct HomeView: View {
    @ObservedObject private var store: StoreOf<HomeReducer>
    private let session: ProfileSession?
    @State private var isPickingRoutineImages = false
    @State private var navigationPath: [DetailRoute] = []
    @State private var deletedRoutineID: String?
    @State private var isHomeDragging = false
    @State private var isSortExpanded = false
    @State private var isProfilePresented = false

    init(store: StoreOf<HomeReducer>, session: ProfileSession? = nil) {
        self.store = store
        self.session = session
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                AppTopBar(
                    AppBrand.serviceName,
                    leading: .asset("Plus", label: "루틴 만들기", accessibilityID: AccessibilityID.Home.createButton) {
                        isPickingRoutineImages = true
                    },
                    trailing: .asset("User", label: "마이프로필") {
                        isProfilePresented = true
                    })

                sortPicker

                routineList
            }
            .background(AppColor.background)
            .routineCreateSwipe(
                profile: profileView, isProfilePresented: $isProfilePresented, isDragging: $isHomeDragging
            ) {
                isPickingRoutineImages = true
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: DetailRoute.self) { route in
                if let session {
                    RoutineDetailDestination(id: route.id, session: session, onBack: closeDetail) {
                        store.send(.removed(route.id))
                        deletedRoutineID = route.id
                    }
                    .id(route.id)
                } else if let detail = route.preview {
                    RoutineDetailDestination(state: detail, onBack: closeDetail)
                        .id(route.id)
                }
            }
        }
        .onChange(of: isProfilePresented) { _, presented in
            if !presented { store.send(.refresh) }
        }
        .task { store.send(.appeared) }
        .routineCreateFlow(isPickingImages: $isPickingRoutineImages, repositories: session?.repositories) { id in
            store.send(.refresh)
            if navigationPath.isEmpty { navigationPath = [DetailRoute(id: id)] }
        }
        .accessibilityIdentifier(AccessibilityID.Root.homeScreen)
    }

    @ViewBuilder
    private var profileView: some View {
        if let session {
            MyProfileView(
                session: session, deletedRoutineID: deletedRoutineID, onRoutineSelected: showRoutine,
                onBack: closeProfile)
        } else {
            #if DEBUG
                MyProfileView(
                    state: MockRoutineData.profile, onRoutineSelected: showRoutine, onBack: closeProfile)
            #else
                EmptyView(title: "계정을 선택해 주세요", message: "")
            #endif
        }
    }

    private func closeDetail() { navigationPath.removeAll() }

    private func closeProfile() {
        closeDetail()
        isHomeDragging = false
        isProfilePresented = false
    }

    private func showRoutine(_ routine: HomeReducer.Routine) {
        guard navigationPath.isEmpty else { return }
        navigationPath = [DetailRoute(id: routine.id, preview: session == nil ? routine.detail : nil)]
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
                if store.state.isLoading && store.state.routines.isEmpty {
                    ProgressView().padding(.top, AppSpacing.lg)
                } else if let message = store.state.error, store.state.routines.isEmpty {
                    listError(message)
                } else if store.state.routines.isEmpty {
                    EmptyView(title: "아직 루틴이 없어요", message: "+ 버튼을 눌러 나만의 루틴을 만들어보세요.")
                        .padding(.top, AppSpacing.lg)
                }
                ForEach(store.state.routines) { routine in
                    Button {
                        guard navigationPath.isEmpty, !isHomeDragging, !isProfilePresented, !isPickingRoutineImages
                        else { return }
                        showRoutine(routine)
                    } label: {
                        RoutineListRow(routine: routine)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(AccessibilityID.Home.routine(routine.id))
                    .onAppear { store.send(.nextPage(routine.id)) }
                }
                if !store.state.routines.isEmpty {
                    if store.state.isLoading { ProgressView().padding() }
                    if let message = store.state.error { listError(message) }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.lg)
        }
        .refreshable {
            store.send(.refresh)
            while store.state.isLoading && !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
        .scrollBounceBehavior(.always)
    }

    private func listError(_ message: String) -> some View {
        ErrorView(title: "루틴 목록을 불러오지 못했어요", message: message, retryTitle: "다시 시도") {
            store.send(.refresh)
        }
    }
}

private struct DetailRoute: Hashable {
    let id: String
    var preview: RoutineDetailReducer.State? = nil

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

#if DEBUG
    #Preview {
        HomeView(store: StoreOf<HomeReducer>(state: MockRoutineData.home, reducer: HomeReducer()))
    }
#endif
