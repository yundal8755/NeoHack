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
            LiveHome(session: session, onSwitchAccount: accounts.signOut)
                .id(session.id)
        } else {
            VStack(spacing: AppSpacing.md) {
                Text("사용자 선택").appFont(AppFont.body1)
                ForEach(ProfileAccounts.Slot.allCases) { item in
                    PrimaryButton(item.rawValue) { accounts.choose(item) }
                        .disabled(accounts.isLoading)
                        .accessibilityIdentifier("account.slot.\(item.rawValue)")
                }
                if accounts.needsToken {
                    SecureField("기기 토큰", text: $accounts.token)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                        .disabled(accounts.isLoading)
                        .onChange(of: accounts.token) { _, _ in accounts.tokenChanged() }
                        .accessibilityIdentifier("account.token")
                    PrimaryButton("프로필 확인", action: accounts.submitToken)
                        .disabled(
                            accounts.isLoading || accounts.token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                }
                ForEach(accounts.candidates, id: \.id) { user in
                    PrimaryButton(user.nickname) { accounts.select(user) }
                        .disabled(accounts.isLoading)
                }
                if accounts.isLoading { ProgressView() }
                if let error = accounts.error { Text(error).foregroundStyle(AppColor.textSecondary) }
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColor.background)
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
    let onSwitchAccount: () -> Void
    @StateObject private var store: StoreOf<HomeReducer>

    init(session: ProfileSession, onSwitchAccount: @escaping () -> Void) {
        self.session = session
        self.onSwitchAccount = onSwitchAccount
        _store = StateObject(
            wrappedValue: StoreOf<HomeReducer>(
                state: .init(), reducer: HomeReducer(repository: session.repositories.routines)))
    }

    var body: some View {
        HomeView(store: store, session: session, onSwitchAccount: onSwitchAccount)
    }
}

#if DEBUG
    private struct MockHome: View {
        @StateObject private var store = StoreOf<HomeReducer>(state: MockRoutineData.home, reducer: HomeReducer())
        var body: some View { HomeView(store: store) }
    }
    #Preview { RootView() }
#endif
