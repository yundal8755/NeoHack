import HackertonCore
import SwiftUI

/// 사용자 선택 화면의 계정 카드. Figma 시안 없이 기존 토큰으로 임시 설계했다.
/// 프로필 사진, 닉네임, 사용 여부 라벨로 구성한다.
///
/// - `.available`: 고를 수 있는 계정. 파란 "사용 가능" 라벨.
/// - `.inUse`: 다른 사람이 쓰고 있는 계정. 흐리게 그리고 누를 수 없다. 회색 "사용 중" 라벨.
/// - `.connecting`: 고른 뒤 계정을 받아오는 중. 주황 테두리와 "연결 중" 라벨.
///
/// 폭은 부모에 맞춰 늘어난다.
struct AccountCard: View {
    enum Status: Equatable {
        case available
        case inUse
        case connecting
    }

    static let avatarSize: CGFloat = 48

    let nickname: String
    let slot: Int
    let profileImageURL: URL?
    let status: Status
    let action: () -> Void

    init(
        nickname: String,
        slot: Int,
        profileImageURL: URL? = nil,
        status: Status,
        action: @escaping () -> Void
    ) {
        self.nickname = nickname
        self.slot = slot
        self.profileImageURL = profileImageURL
        self.status = status
        self.action = action
    }

    var body: some View {
        Button {
            HapticFeedbackManager.shared.impact(style: .soft)
            action()
        } label: {
            HStack(spacing: AppSpacing.sm) {
                ProfileAvatar(url: profileImageURL, size: Self.avatarSize)
                    .opacity(status == .inUse ? AppOpacity.disabled : 1)

                Text(verbatim: nickname)
                    .appFont(AppFont.body1)
                    .foregroundStyle(status == .inUse ? AppColor.textDisabled : AppColor.textPrimary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                AccountStatusLabel(status: status)
            }
        }
        .buttonStyle(AccountCardButtonStyle(status: status))
        .disabled(status != .available)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: nickname))
        .accessibilityValue(Text(verbatim: AccountStatusLabel.title(for: status)))
        .accessibilityHint(status == .available ? Text(verbatim: "이 계정으로 시작해요") : Text(verbatim: ""))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(AccessibilityID.AccountSelect.card(slot))
    }
}

extension AccountCard {
    /// 서버 계정 목록의 항목으로 카드를 만든다. `isConnecting`이면 사용 가능 여부보다 연결 중 표시를 먼저 보인다.
    init(account: TestAccount, profileImageURL: URL? = nil, isConnecting: Bool = false, action: @escaping () -> Void) {
        self.init(
            nickname: account.nickname,
            slot: account.slot,
            profileImageURL: profileImageURL ?? account.profileImageURL,
            status: isConnecting ? .connecting : (account.available ? .available : .inUse),
            action: action
        )
    }
}

private struct AccountCardButtonStyle: ButtonStyle {
    let status: AccountCard.Status

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
        configuration.label
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(shape.fill(background(isPressed: configuration.isPressed)))
            .overlay(shape.strokeBorder(border, lineWidth: status == .connecting ? 1.5 : 1))
            .contentShape(shape)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.2), value: status)
    }

    private func background(isPressed: Bool) -> Color {
        switch status {
        case .available: isPressed ? AppColor.gray50 : AppColor.surfaceRaised
        case .inUse: AppColor.gray50
        case .connecting: AppColor.surfaceRaised
        }
    }

    private var border: Color {
        status == .connecting ? AppColor.primary : AppColor.gray200
    }
}

/// 카드 오른쪽의 사용 여부 라벨.
struct AccountStatusLabel: View {
    let status: AccountCard.Status

    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            if status == .connecting {
                ProgressView()
                    .controlSize(.mini)
                    .tint(AppColor.primary)
            }
            Text(verbatim: Self.title(for: status))
                .appFont(AppFont.caption2.weight(.semiBold))
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, AppSpacing.xxxs)
        .background(Capsule().fill(background))
        .fixedSize()
    }

    static func title(for status: AccountCard.Status) -> String {
        switch status {
        case .available: "사용 가능"
        case .inUse: "사용 중"
        case .connecting: "연결 중"
        }
    }

    private var foreground: Color {
        switch status {
        case .available: AppColor.secondaryBlue500
        case .inUse: AppColor.textSecondary
        case .connecting: AppColor.primary
        }
    }

    private var background: Color {
        switch status {
        case .available: AppColor.secondaryBlue50
        case .inUse: AppColor.gray200
        case .connecting: AppColor.primarySoft
        }
    }
}

#Preview("상태별 카드") {
    VStack(spacing: AppSpacing.sm) {
        AccountCard(nickname: "김햄찌", slot: 1, status: .available) {}
        AccountCard(nickname: "박다람", slot: 2, status: .connecting) {}
        AccountCard(nickname: "이토끼", slot: 3, status: .inUse) {}
    }
    .padding(AppSpacing.md)
}

#Preview("사용자 선택 화면 구성") {
    VStack(spacing: 0) {
        AccountSelectHeader {}
        ScrollView {
            VStack(spacing: AppSpacing.sm) {
                AccountCard(nickname: "김햄찌", slot: 1, status: .available) {}
                AccountCard(nickname: "박다람", slot: 2, status: .connecting) {}
                AccountCard(nickname: "이토끼", slot: 3, status: .inUse) {}
                AccountCard(nickname: "최부엉", slot: 4, status: .available) {}
                AccountCard(nickname: "정펭귄", slot: 5, status: .inUse) {}
            }
            .padding(AppSpacing.md)
        }
        .scrollIndicators(.hidden)
    }
    .background(AppColor.background)
}
