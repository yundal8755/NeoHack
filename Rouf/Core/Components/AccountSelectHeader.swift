import SwiftUI

/// 사용자 선택 화면 헤더. 가운데 제목과 오른쪽 새로고침 버튼으로 구성한다.
/// 기존 `AppTopBar`를 그대로 쓰고, 목록을 불러오는 중에는 새로고침 버튼을 비활성화한다.
struct AccountSelectHeader: View {
    let title: String
    let isRefreshing: Bool
    let onRefresh: () -> Void

    init(_ title: String = "사용자 선택", isRefreshing: Bool = false, onRefresh: @escaping () -> Void) {
        self.title = title
        self.isRefreshing = isRefreshing
        self.onRefresh = onRefresh
    }

    var body: some View {
        AppTopBar(
            title,
            trailing: AppTopBar.Item(
                content: .icon(systemName: "arrow.clockwise", label: "계정 목록 새로고침"),
                action: onRefresh,
                isEnabled: !isRefreshing
            )
        )
        .overlay(alignment: .trailing) {
            if isRefreshing {
                // 비활성화된 아이콘 위에 진행 표시를 겹쳐 불러오는 중임을 보인다.
                ProgressView()
                    .tint(AppColor.grayBlack)
                    .frame(width: 24, height: 24)
                    .background(AppColor.background)
                    .padding(.trailing, AppSpacing.md)
                    .accessibilityLabel(Text(verbatim: "계정 목록을 불러오는 중"))
            }
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.lg) {
        AccountSelectHeader {}
        AccountSelectHeader(isRefreshing: true) {}
    }
}
