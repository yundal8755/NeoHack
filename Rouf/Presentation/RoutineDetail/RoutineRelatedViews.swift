import RoufCore
import MVICore
import SwiftUI

nonisolated struct RoutineRelatedLoader<Value: Equatable & Sendable>: Reducer {
    enum State: Equatable {
        case loading
        case loaded(Value)
        case failed(String)
    }

    enum Action {
        case load
        case finished(State)
    }

    let fetch: () async throws -> Value

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .load:
            state = .loading
            return .run { send in
                do {
                    let value = try await fetch()
                    try Task.checkCancellation()
                    await send(.finished(.loaded(value)))
                }
                catch {
                    if !Task.isCancelled { await send(.finished(.failed(error.localizedDescription))) }
                }
            }.cancelTask(id: "related")
        case let .finished(value):
            state = value
            return .none
        }
    }
}

struct ParticipationResultsView: View {
    let routineID: String
    let session: ProfileSession
    let onChange: () -> Void

    @StateObject private var store: StoreOf<RoutineRelatedLoader<RoutineParticipationResults>>
    @State private var path: [String] = []
    @Environment(\.dismiss) private var dismiss

    init(
        routineID: String, session: ProfileSession,
        store: StoreOf<RoutineRelatedLoader<RoutineParticipationResults>>? = nil,
        onChange: @escaping () -> Void
    ) {
        self.routineID = routineID
        self.session = session
        self.onChange = onChange
        let routines = session.repositories.routines
        _store = StateObject(wrappedValue: store ?? Store(
            state: .loading, reducer: RoutineRelatedLoader { try await routines.participationResults(routineID: routineID) }))
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                AppTopBar("참여 기록", leading: .asset("CaretLeft", label: "닫기") { dismiss() })
                content
                    .padding(.horizontal, AppSpacing.md)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(AppColor.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { participantID in
                RoutineDetailDestination(
                    id: routineID, session: session, resultParticipantID: participantID,
                    onUpdated: refreshAfterChange,
                    onBack: { path.removeAll() },
                    onDelete: {
                        path.removeAll()
                        refreshAfterChange()
                    })
            }
        }
        .task { if case .loading = store.state { store.send(.load) } }
        .accessibilityIdentifier(AccessibilityID.RoutineDetail.resultsScreen)
    }

    @ViewBuilder private var content: some View {
        switch store.state {
        case .loading:
            LoadingView("참여 기록을 불러오는 중이에요")
        case let .failed(message):
            ErrorView(title: "참여 기록을 불러오지 못했어요", message: message, retryTitle: "다시 시도") {
                store.send(.load)
            }
        case let .loaded(page):
            let results = (page.results ?? []).filter { $0.participant != nil }
            if results.isEmpty {
                EmptyView(title: "아직 공개된 참여 기록이 없어요", message: "완료한 참여 기록이 여기에 표시돼요.")
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.sm) {
                        ForEach(results, id: \.participant?.id) { result in
                            if let participant = result.participant {
                                Button { path.append(participant.id) } label: {
                                    HStack(spacing: AppSpacing.sm) {
                                        NetworkImageView(
                                            url: result.thumbnailURL, downsamplingSize: CGSize(width: 64, height: 64),
                                            borderColor: nil, showsLoadingText: false)
                                            .frame(width: 64, height: 64)
                                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
                                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                            if let title = result.title { Text(title).appFont(AppFont.body2) }
                                            if let nickname = participant.nickname { Text(nickname).appFont(AppFont.caption1) }
                                        }
                                        Spacer(minLength: 0)
                                        Image(systemName: "chevron.right")
                                    }
                                    .foregroundStyle(AppColor.textPrimary)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, AppSpacing.sm)
                }
                .refreshable { store.send(.load) }
            }
        }
    }

    private func refreshAfterChange() {
        store.send(.load)
        onChange()
    }
}

struct PublicProfileView: View {
    @StateObject private var store: StoreOf<RoutineRelatedLoader<UserEntity>>
    @Environment(\.dismiss) private var dismiss
    private let session: ProfileSession?
    private let onBack: (() -> Void)?
    @State private var selectedRoutine: HomeReducer.Routine?
    @State private var routineUpdatedID: UUID?
    @State private var deletedRoutineID: String?

    init(
        publicID: String, users: any UserRepository,
        store: StoreOf<RoutineRelatedLoader<UserEntity>>? = nil,
        session: ProfileSession? = nil, onBack: (() -> Void)? = nil
    ) {
        self.session = session
        self.onBack = onBack
        _store = StateObject(wrappedValue: store ?? Store(
            state: .loading, reducer: RoutineRelatedLoader { try await users.profile(publicID: publicID) }))
    }

    var body: some View {
        Group {
            if case let .loaded(profile) = store.state, let session {
                MyProfileView(session: session, deletedRoutineID: deletedRoutineID, viewedProfile: profile,
                              routineUpdatedID: routineUpdatedID, onRoutineSelected: { routine in
                    guard selectedRoutine == nil else { return }
                    selectedRoutine = routine
                }, onBack: close)
                .id(profile.id)
            } else {
                VStack(spacing: 0) {
                    AppTopBar("프로필", leading: .asset("CaretLeft", label: "뒤로가기", action: close))
                    content
                        .padding(AppSpacing.md)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .background(AppColor.background)
        .task { if case .loading = store.state { store.send(.load) } }
        .accessibilityIdentifier(AccessibilityID.RoutineDetail.publicProfileScreen)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: Binding(
            get: { selectedRoutine != nil }, set: { if !$0 { selectedRoutine = nil } }
        )) {
            if let routine = selectedRoutine, let session {
                RoutineDetailDestination(id: routine.id, session: session,
                    resultParticipantID: routine.resultParticipantID,
                    onParticipationCompleted: {
                        selectedRoutine = nil
                        routineUpdatedID = UUID()
                    }, onUpdated: { routineUpdatedID = UUID() },
                    onBack: { selectedRoutine = nil }, onDelete: {
                        selectedRoutine = nil
                        deletedRoutineID = routine.id
                        routineUpdatedID = UUID()
                    })
                    .id(routine.id + (routine.resultParticipantID ?? ""))
            }
        }
    }

    private func close() {
        if let onBack { onBack() } else { dismiss() }
    }

    @ViewBuilder private var content: some View {
        switch store.state {
        case .loading:
            LoadingView("프로필을 불러오는 중이에요")
        case let .failed(message):
            ErrorView(title: "프로필을 불러오지 못했어요", message: message, retryTitle: "다시 시도") {
                store.send(.load)
            }
        case let .loaded(profile):
            VStack(spacing: AppSpacing.sm) {
                ProfileAvatar(url: profile.profileImageURL, size: 88)
                Text(profile.nickname)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.textPrimary)
                if let bio = profile.bio, !bio.isEmpty {
                    Text(bio)
                        .appFont(AppFont.body2)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}
