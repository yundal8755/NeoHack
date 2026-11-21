import HackertonCore
import MVICore
import SwiftUI

struct HomeView: View {
    @ObservedObject private var store: StoreOf<HomeReducer>
    private let session: ProfileSession?
    private let onSwitchAccount: () -> Void
    @State private var path: [String] = []
    @State private var isPickingRoutineImages = false
    @State private var isSortExpanded = false
    @State private var isProfilePresented = false

    init(store: StoreOf<HomeReducer>, session: ProfileSession? = nil, onSwitchAccount: @escaping () -> Void = {}) {
        self.store = store
        self.session = session
        self.onSwitchAccount = onSwitchAccount
    }

    var body: some View {
        NavigationStack(path: $path) {
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
            .navigationDestination(for: String.self) { id in
                if let session {
                    HomeRoutineDetailDestination(id: id, session: session) { store.send(.removed(id)) }
                } else if let routine = store.state.routines.first(where: { $0.id == id }) {
                    HomeRoutineDetailDestination(state: routine.detail)
                }
            }
            .onChange(of: isProfilePresented) { _, presented in
                if !presented { store.send(.refresh) }
            }
            .navigationDestination(isPresented: $isProfilePresented) {
                if let session {
                    MyProfileView(session: session, onSwitchAccount: onSwitchAccount)
                } else {
                    VStack {
                        AppTopBar("마이프로필", leading: .asset("CaretLeft", label: "뒤로가기") {
                            isProfilePresented = false
                        })
                        EmptyView(title: "마이프로필", message: "프로필 화면을 준비하고 있어요.", systemImage: "person")
                        Spacer()
                    }
                    .background(AppColor.background)
                    .toolbar(.hidden, for: .navigationBar)
                }
            }
        }
        .task { store.send(.appeared) }
        .routineCreateFlow(isPickingImages: $isPickingRoutineImages, repositories: session?.repositories) { id in
            store.send(.refresh)
            path.append(id)
        }
        .accessibilityIdentifier(AccessibilityID.Root.homeScreen)
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
                .frame(minHeight: 44)
                .contentShape(Rectangle())
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
                        } else if let error = store.state.error, store.state.routines.isEmpty {
                            ErrorView(title: "루틴 목록을 불러오지 못했어요", message: error, retryTitle: "다시 시도") { store.send(.refresh) }
                        } else if store.state.routines.isEmpty {
                            EmptyView(title: "아직 루틴이 없어요", message: "+ 버튼을 눌러 나만의 루틴을 만들어보세요.")
                                .padding(.top, AppSpacing.lg)
                        }
                        ForEach(store.state.routines) { routine in
                            NavigationLink(value: routine.id) {
                                routineRow(routine)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier(AccessibilityID.Home.routine(routine.id))
                            .onAppear { store.send(.nextPage(routine.id)) }
                        }
                        if !store.state.routines.isEmpty {
                            if store.state.isLoading { ProgressView().padding() }
                            if let error = store.state.error {
                                ErrorView(title: "루틴 목록을 불러오지 못했어요", message: error, retryTitle: "다시 시도") { store.send(.refresh) }
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, 88)
                }
                .refreshable {
                    store.send(.refresh)
                    while store.state.isLoading && !Task.isCancelled {
                        try? await Task.sleep(for: .milliseconds(50))
                    }
                }
                .scrollBounceBehavior(.always)
    }

    private func routineRow(_ routine: HomeReducer.Routine) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
                    ProfileAvatar(url: routine.avatarURL, size: 35)
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
                            authorName(routine.nickname)
                            createdDate(routine.createdAt)
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            authorName(routine.nickname)
                            createdDate(routine.createdAt)
                        }
                    }
                }
                .padding(.vertical, AppSpacing.xxs)

                Text(routine.detail.title)
                    .appFont(AppFont.body1)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                    .padding(.vertical, AppSpacing.xxxs)
                Text(routine.introduction)
                    .appFont(AppFont.caption1)
                    .foregroundStyle(AppColor.gray600)
                    .lineLimit(2)
                    .padding(.vertical, AppSpacing.xxxs)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppSpacing.buttonPadding) {
                        routineCounts(routine)
                        participationBadge(routine.detail.participation)
                    }
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        routineCounts(routine)
                        participationBadge(routine.detail.participation)
                    }
                }
                .padding(.vertical, AppSpacing.xxs)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Group {
                if let url = routine.thumbnailURL ?? routine.detail.steps.first?.imageURL {
                    NetworkImageView(
                        url: url, cornerRadius: AppRadius.button,
                        downsamplingSize: CGSize(width: 115, height: 115),
                        accessibilityLabel: "루틴 대표 이미지", borderColor: nil, showsLoadingText: false
                    )
                } else {
                    RoundedRectangle(cornerRadius: AppRadius.button).fill(AppColor.gray400)
                }
            }
            .frame(width: 115, height: 115)
        }
        .padding(.vertical, AppSpacing.md)
        .contentShape(Rectangle())
    }

    private func authorName(_ name: String) -> some View {
        Text(name).appFont(AppFont.body2).foregroundStyle(AppColor.grayBlack)
    }

    private func createdDate(_ date: Date?) -> some View {
        Text(date.map(Self.dateFormatter.string(from:)) ?? "")
            .appFont(AppFont.caption2)
            .foregroundStyle(AppColor.gray500)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy. MM. dd HH:mm"
        return formatter
    }()

    private func routineCounts(_ routine: HomeReducer.Routine) -> some View {
        HStack(spacing: AppSpacing.buttonPadding) {
            count(routine.detail.isLiked ? "HomeHeartFilled" : "Heart", value: routine.detail.likeCount)
            if let participants = routine.participantCount {
                count("User", value: participants)
            } else if !routine.isServerRow {
                count("ChatCircle", value: routine.detail.commentCount)
            }
        }
    }

    @ViewBuilder
    private func participationBadge(_ participation: RoutineDetailReducer.Participation) -> some View {
        if participation != .notJoined {
            Text(participation.rawValue)
                .appFont(AppFont.caption1.weight(.medium))
                .foregroundStyle(participation == .joined ? Color(hexCode: "#3C771B") : AppColor.gray500)
                .padding(.horizontal, AppSpacing.buttonPadding)
                .padding(.vertical, AppSpacing.xxxs)
                .background(participation == .joined ? Color(hexCode: "#D3FBBB") : AppColor.surface, in: Capsule())
                .fixedSize()
        }
    }

    private func count(_ asset: String, value: Int) -> some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(asset).frame(width: 24, height: 24)
            Text("\(value)").appFont(AppFont.caption1)
        }
        .foregroundStyle(AppColor.gray800)
    }
}

struct HomeRoutineDetailDestination: View {
    @StateObject private var store: StoreOf<RoutineDetailReducer>
    private let onDelete: () -> Void

    init(id: String, session: ProfileSession, onDelete: @escaping () -> Void) {
        var state = RoutineDetailReducer.State(title: "루틴 상세")
        state.isLive = true
        _store = StateObject(wrappedValue: StoreOf<RoutineDetailReducer>(
            state: state, reducer: RoutineDetailReducer(
                id: id, userID: session.profile.id, routines: session.repositories.routines,
                comments: session.repositories.comments)))
        self.onDelete = onDelete
    }

    init(state: RoutineDetailReducer.State) {
        _store = StateObject(wrappedValue: StoreOf<RoutineDetailReducer>(state: state, reducer: RoutineDetailReducer()))
        onDelete = {}
    }

    var body: some View { RoutineDetailView(store: store, onDelete: onDelete) }
}

#if DEBUG
#Preview {
    HomeView(store: StoreOf<HomeReducer>(state: MockRoutineData.home, reducer: HomeReducer()))
}
#endif
