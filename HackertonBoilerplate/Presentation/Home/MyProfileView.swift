import MVICore
import SwiftUI

struct MyProfileView: View {
    let session: ProfileSession
    let onSwitchAccount: () -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store: StoreOf<HomeReducer>

    init(session: ProfileSession, onSwitchAccount: @escaping () -> Void) {
        self.session = session
        self.onSwitchAccount = onSwitchAccount
        _store = StateObject(
            wrappedValue: StoreOf<HomeReducer>(
                state: .init(),
                reducer: HomeReducer(
                    repository: session.repositories.routines, authorID: session.profile.id)))
    }

    var body: some View {
        VStack(spacing: 0) {
            AppTopBar("마이프로필", leading: .asset("CaretLeft", label: "뒤로가기") { dismiss() })
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack {
                        ProfileAvatar(url: session.profileImageURL, size: 56)
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(session.profile.nickname).appFont(AppFont.body1)
                            if let bio = session.profile.bio, !bio.isEmpty {
                                Text(bio).foregroundStyle(AppColor.textSecondary)
                            }
                        }
                        Spacer()
                        Button("계정 전환", action: onSwitchAccount)
                    }
                    Text("내 루틴").appFont(AppFont.body1)
                    ForEach(store.state.routines) { routine in
                        NavigationLink(value: ProfileRoutine(id: routine.id)) {
                            HStack {
                                Text(routine.detail.title)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding(.vertical, AppSpacing.xs)
                        }
                        .onAppear { store.send(.nextPage(routine.id)) }
                    }
                    if store.state.isLoading {
                        ProgressView()
                    } else if let message = store.state.error {
                        ErrorView(title: "내 루틴을 불러오지 못했어요", message: message, retryTitle: "다시 시도") {
                            store.send(.refresh)
                        }
                    } else if store.state.routines.isEmpty {
                        EmptyView(title: "아직 만든 루틴이 없어요", message: "홈에서 루틴을 만들 수 있어요.")
                    }
                }
                .padding(AppSpacing.md)
            }
        }
        .background(AppColor.background)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: ProfileRoutine.self) { routine in
            HomeRoutineDetailDestination(id: routine.id, session: session) {
                store.send(.removed(routine.id))
            }
        }
        .task { store.send(.appeared) }
    }

}

private struct ProfileRoutine: Hashable { let id: String }

struct ProfileAvatar: View {
    let url: URL?
    let size: CGFloat

    var body: some View {
        Group {
            if let url {
                NetworkImageView(
                    url: url, cornerRadius: size / 2,
                    downsamplingSize: CGSize(width: size, height: size),
                    borderColor: nil, showsLoadingText: false)
            } else {
                Image("RoutineDetailAvatar").resizable()
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
