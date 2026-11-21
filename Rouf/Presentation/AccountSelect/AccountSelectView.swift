import RoufCore
import SwiftUI

/// 사용자 선택 화면. 테스트 계정 목록을 카드로 보여주고, 고른 계정으로 시작한다.
/// Figma 시안 없이 `AccountSelectHeader`와 `AccountCard`로 구성했다.
///
/// 목록이 비어 있으면 상태에 따라 불러오는 중·오류·빈 목록 안내를 보이고,
/// 목록이 있는 상태에서 난 오류(계정 선택 실패 등)는 상단 토스트로 알린다.
struct AccountSelectView: View {
    let entries: [TestAccount]
    let connectingID: String?
    let isLoading: Bool
    let error: String?
    let onSelect: (TestAccount) -> Void
    let onRefresh: () async -> Void
    let onDismissError: () -> Void

    @State private var feedbackID = UUID()

    init(
        entries: [TestAccount],
        connectingID: String? = nil,
        isLoading: Bool = false,
        error: String? = nil,
        onSelect: @escaping (TestAccount) -> Void = { _ in },
        onRefresh: @escaping () async -> Void = {},
        onDismissError: @escaping () -> Void = {}
    ) {
        self.entries = entries
        self.connectingID = connectingID
        self.isLoading = isLoading
        self.error = error
        self.onSelect = onSelect
        self.onRefresh = onRefresh
        self.onDismissError = onDismissError
    }

    var body: some View {
        VStack(spacing: 0) {
            AccountSelectHeader(isRefreshing: isLoading && connectingID == nil) {
                Task { await onRefresh() }
            }

            if entries.isEmpty {
                placeholder
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                accountList
            }
        }
        .background(AppColor.background.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.AccountSelect.screen)
        .feedbackPopup(Binding(
            get: {
                guard !entries.isEmpty, let error else { return nil }
                return FeedbackMessage(id: feedbackID, kind: .error, title: "요청을 처리하지 못했어요", message: error)
            },
            set: { if $0 == nil { onDismissError() } }
        ))
    }

    private var accountList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.sm) {
                ForEach(entries) { account in
                    AccountCard(account: account, isConnecting: account.id == connectingID) {
                        onSelect(account)
                    }
                }
            }
            .padding(AppSpacing.md)
        }
        .scrollIndicators(.hidden)
        .refreshable { await onRefresh() }
        // 계정을 받아오는 동안에는 다른 카드를 고르지 못하게 한다.
        .disabled(isLoading)
    }

    @ViewBuilder
    private var placeholder: some View {
        if isLoading {
            LoadingView("계정 목록을 불러오는 중이에요")
        } else if let error {
            ErrorView(
                title: "계정 목록을 불러오지 못했어요",
                message: error,
                retryTitle: "다시 시도",
                retry: { Task { await onRefresh() } }
            )
        } else {
            Rouf.EmptyView(
                title: "등록된 테스트 계정이 없어요",
                message: "새로고침을 눌러 다시 확인해 주세요.",
                systemImage: "person.2"
            )
        }
    }
}

#if DEBUG
    extension TestAccount {
        static let previewEntries: [TestAccount] = [
            TestAccount(id: "1", slot: 1, nickname: "김햄찌", available: true),
            TestAccount(id: "2", slot: 2, nickname: "박다람", available: true),
            TestAccount(id: "3", slot: 3, nickname: "이토끼", available: false),
            TestAccount(id: "4", slot: 4, nickname: "최부엉", available: true),
            TestAccount(id: "5", slot: 5, nickname: "정펭귄", available: false),
        ]
    }

    #Preview("목록") { AccountSelectView(entries: TestAccount.previewEntries) }
    #Preview("연결 중") { AccountSelectView(entries: TestAccount.previewEntries, connectingID: "2", isLoading: true) }
    #Preview("불러오는 중") { AccountSelectView(entries: [], isLoading: true) }
    #Preview("빈 목록") { AccountSelectView(entries: []) }
    #Preview("오류") { AccountSelectView(entries: [], error: "서버에 연결하지 못했어요.") }
#endif
