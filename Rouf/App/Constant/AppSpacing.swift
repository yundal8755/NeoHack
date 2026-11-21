import Foundation

enum AppSpacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48

    // MARK: - Figma 컴포넌트 간격

    /// 버튼 안쪽 여백.
    static let buttonPadding: CGFloat = 10
    /// 입력창 좌우 여백.
    static let inputHorizontal: CGFloat = 18
    /// 입력창 위아래 여백.
    static let inputVertical: CGFloat = 8
    /// 입력 항목 제목과 입력창 사이.
    static let fieldLabelGap: CGFloat = 6
    /// "시간" 라벨과 시간 칩 사이.
    static let inlineLabelGap: CGFloat = 10
}
