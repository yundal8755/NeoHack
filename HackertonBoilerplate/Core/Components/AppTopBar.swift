import HackertonCore
import SwiftUI

/// Figma `상단바` 컴포넌트. 가운데 제목과 좌우 항목(아이콘 또는 텍스트)으로 구성한다.
///
/// Figma 변형별 사용 예:
/// - 홈: `AppTopBar("서비스명", leading: .add {}, trailing: .profile {})`
/// - 상세: `AppTopBar("서비스명", leading: .back {})`
/// - 루틴 만들기: `AppTopBar("루틴 만들기", trailing: .exit {})`
/// - 루틴 상세: `AppTopBar("김햄찌의 하루", leading: .back {}, trailing: .more {})`
///
/// 시스템 내비게이션 바 대신 쓰므로 화면에서 `.toolbar(.hidden, for: .navigationBar)`를 함께 건다.
/// 아이콘은 Figma 아이콘 에셋이 준비될 때까지 SF Symbol을 쓴다.
struct AppTopBar: View {
    struct Item {
        enum Content {
            case icon(systemName: String, label: String)
            case text(String)
        }

        let content: Content
        let action: () -> Void

        static func icon(_ systemName: String, label: String, action: @escaping () -> Void) -> Item {
            Item(content: .icon(systemName: systemName, label: label), action: action)
        }

        static func text(_ title: String, action: @escaping () -> Void) -> Item {
            Item(content: .text(title), action: action)
        }

        static func back(_ action: @escaping () -> Void) -> Item {
            .icon("chevron.left", label: "뒤로가기", action: action)
        }

        static func add(_ action: @escaping () -> Void) -> Item {
            .icon("plus", label: "추가", action: action)
        }

        static func profile(_ action: @escaping () -> Void) -> Item {
            .icon("person", label: "내 정보", action: action)
        }

        static func more(_ action: @escaping () -> Void) -> Item {
            .icon("ellipsis", label: "더보기", action: action)
        }

        static func exit(_ action: @escaping () -> Void) -> Item {
            .text("나가기", action: action)
        }
    }

    let title: String
    let leading: Item?
    let trailing: Item?

    init(_ title: String, leading: Item? = nil, trailing: Item? = nil) {
        self.title = title
        self.leading = leading
        self.trailing = trailing
    }

    var body: some View {
        ZStack {
            Text(verbatim: title)
                .appFont(AppFont.title1)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, Self.titleInset)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 0) {
                if let leading {
                    itemView(leading)
                        .accessibilityIdentifier(AccessibilityID.TopBar.leadingButton)
                }
                Spacer(minLength: 0)
                if let trailing {
                    itemView(trailing)
                        .accessibilityIdentifier(AccessibilityID.TopBar.trailingButton)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xxs)
        .frame(maxWidth: .infinity)
        .background(AppColor.background)
    }

    /// 제목이 좌우 항목(아이콘 24pt, "나가기" 텍스트)과 겹치지 않게 두는 여백.
    private static let titleInset: CGFloat = 48

    @ViewBuilder
    private func itemView(_ item: Item) -> some View {
        switch item.content {
        case let .icon(systemName, label):
            Button(action: item.action) {
                Image(systemName: systemName)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(AppColor.grayBlack)
                    .frame(width: Self.iconSize, height: Self.iconSize)
                    .rotationEffect(systemName == "ellipsis" ? .degrees(90) : .zero)
                    .contentShape(Rectangle().inset(by: -10))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: label))

        case let .text(title):
            Button(action: item.action) {
                Text(verbatim: title)
                    .appFont(AppFont.body2)
                    .foregroundStyle(AppColor.gray300)
                    .contentShape(Rectangle().inset(by: -10))
            }
            .buttonStyle(.plain)
        }
    }

    private static let iconSize: CGFloat = 24
}

#Preview {
    VStack(spacing: AppSpacing.lg) {
        AppTopBar("서비스명", leading: .add {}, trailing: .profile {})
        AppTopBar("서비스명", leading: .back {})
        AppTopBar("루틴 만들기", trailing: .exit {})
        AppTopBar("김햄찌의 하루", leading: .back {}, trailing: .more {})
    }
}
