import HackertonCore
import MVICore
import Observation
import SwiftUI

struct RootView: View {
    private let configuration: AppLaunchConfiguration
    @StateObject private var accounts: ProfileAccounts

    init(container: AppContainer = .shared) {
        self.configuration = container.configuration
        _accounts = StateObject(wrappedValue: ProfileAccounts(container: container))
    }

    var body: some View {
        Group {
            #if DEBUG
                if case .mock = configuration.dataMode {
                    MockHome()
                } else {
                    liveContent
                }
            #else
                liveContent
            #endif
        }
    }

    @ViewBuilder
    private var liveContent: some View {
        if let session = accounts.session {
            LiveHome(session: session)
                .id(session.id)
        } else {
            VStack(spacing: AppSpacing.md) {
                Text("사용자 선택").appFont(AppFont.body1)
                ForEach(accounts.entries) { account in
                    PrimaryButton(account.available ? account.nickname : "\(account.nickname) (사용 중)") {
                        accounts.choose(account)
                    }
                    .disabled(accounts.isLoading || !account.available)
                    .accessibilityIdentifier("account.slot.\(account.slot)")
                }
                if accounts.entries.isEmpty && !accounts.isLoading && accounts.error == nil {
                    Text("등록된 테스트 계정이 없어요.")
                }
                Button("계정 목록 새로고침") { Task { await accounts.load() } }
                    .disabled(accounts.isLoading)
                if accounts.isLoading { ProgressView() }
                if let error = accounts.error { Text(error).foregroundStyle(AppColor.textSecondary) }
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColor.background)
            .task { if accounts.entries.isEmpty { await accounts.load() } }
        }
    }

}

@Observable
final class ProfileSession: Identifiable {
    let id = UUID()
    var profile: UserEntity
    let repositories: AppContainer.ProfileRepositories

    init(profile: UserEntity, repositories: AppContainer.ProfileRepositories) {
        self.profile = profile
        self.repositories = repositories
    }

    var profileImageURL: URL? {
        guard let imageID = profile.profileImageID else { return nil }
        return try? ImageEndpoint.data(id: imageID).asURLRequest().url
    }
}

private struct LiveHome: View {
    let session: ProfileSession
    @StateObject private var store: StoreOf<HomeReducer>

    init(session: ProfileSession) {
        self.session = session
        _store = StateObject(
            wrappedValue: StoreOf<HomeReducer>(
                state: .init(), reducer: HomeReducer(repository: session.repositories.routines)))
    }

    var body: some View {
        HomeView(store: store, session: session)
    }
}

#if DEBUG
    private struct MockHome: View {
        @StateObject private var store = StoreOf<HomeReducer>(state: MockRoutineData.home, reducer: HomeReducer())
        var body: some View { HomeView(store: store) }
    }
    #Preview { RootView() }
#endif
