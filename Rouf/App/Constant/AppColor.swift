import SwiftUI

/// Figma `너디터리 해커톤` 파일의 컬러 변수와 같은 이름·값을 쓴다.
/// Figma에 있는 변수: Primary/500, Gray/200~900, Gray/Black, Gray/White.
/// Gray 50·100과 필수 표시 빨강은 변수는 아니지만 디자인에서 쓰는 값이다.
enum AppColor {
    enum Primary {
        static let primary500 = Color(hexCode: "#FF842B")
    }

    enum Gray {
        /// Figma 변수 아님. 연한 배경용.
        static let gray50 = Color(hexCode: "#FAFAFA")
        /// Figma 변수 아님. 시간 선택 시트의 취소 버튼 배경.
        static let gray100 = Color(hexCode: "#F2F2F2")
        static let gray200 = Color(hexCode: "#E6E6E6")
        static let gray300 = Color(hexCode: "#CCCCCC")
        static let gray400 = Color(hexCode: "#B3B3B3")
        static let gray500 = Color(hexCode: "#808080")
        static let gray600 = Color(hexCode: "#666666")
        static let gray700 = Color(hexCode: "#4D4D4D")
        static let gray800 = Color(hexCode: "#333333")
        static let gray900 = Color(hexCode: "#262626")
        static let black = Color(hexCode: "#1A1A1A")
        static let white = Color(hexCode: "#FFFFFF")
    }

    enum Secondary {
        static let secondary50 = Color(hexCode: "#EFF0FA")
        static let secondary100 = Color(hexCode: "#D5DAF2")
        static let secondary200 = Color(hexCode: "#AEB8E6")
        static let secondary300 = Color(hexCode: "#8B9BDB")
        static let secondary400 = Color(hexCode: "#6E82CE")
        static let secondary500 = Color(hexCode: "#4D68B8")
        static let secondary600 = Color(hexCode: "#3D5294")
        static let secondary700 = Color(hexCode: "#2D3E72")
        static let secondary800 = Color(hexCode: "#212F58")
        static let secondary900 = Color(hexCode: "#121B37")
    }

    enum Point {
        static let red = Color(hexCode: "#C51D23")
        /// 입력 항목의 필수 표시(*).
        static let requiredRed = Color(hexCode: "#F23B4E")
        static let orange = Color(hexCode: "#FF8453")
        static let yellow = Color(hexCode: "#FEDB7D")
        static let skyBlue = Color(hexCode: "#D7F0FA")
    }

    static let primary500 = Primary.primary500

    static let gray50 = Gray.gray50
    static let gray100 = Gray.gray100
    static let gray200 = Gray.gray200
    static let gray300 = Gray.gray300
    static let gray400 = Gray.gray400
    static let gray500 = Gray.gray500
    static let gray600 = Gray.gray600
    static let gray700 = Gray.gray700
    static let gray800 = Gray.gray800
    static let gray900 = Gray.gray900
    static let grayBlack = Gray.black

    static let secondaryBlue50 = Secondary.secondary50
    static let secondaryBlue100 = Secondary.secondary100
    static let secondaryBlue200 = Secondary.secondary200
    static let secondaryBlue300 = Secondary.secondary300
    static let secondaryBlue400 = Secondary.secondary400
    static let secondaryBlue500 = Secondary.secondary500
    static let secondaryBlue600 = Secondary.secondary600
    static let secondaryBlue700 = Secondary.secondary700
    static let secondaryBlue800 = Secondary.secondary800
    static let secondaryBlue900 = Secondary.secondary900

    static let pointRed = Point.red
    static let pointOrange = Point.orange
    static let pointYellow = Point.yellow
    static let pointSkyBlue = Point.skyBlue
    static let required = Point.requiredRed

    // MARK: - 의미 토큰

    static let background = white
    static let surface = Gray.gray100
    static let surfaceRaised = white
    static let primary = Primary.primary500
    static let primarySoft = Primary.primary500.opacity(0.12)
    static let accent = Primary.primary500
    static let accentSoft = Point.yellow
    static let ink = textPrimary
    /// 제목·본문. Figma 텍스트의 `black`.
    static let textPrimary = Color(hexCode: "#000000")
    /// 입력된 텍스트.
    static let textInput = Gray.gray900
    /// 안내 문구.
    static let textSecondary = Gray.gray600
    /// placeholder, 비활성 텍스트 링크(나가기).
    static let textTertiary = Gray.gray400
    static let textDisabled = Gray.gray500
    static let border = Gray.gray400
    static let fillDisabled = Gray.gray200
    static let success = Secondary.secondary500
    static let warning = Point.orange
    static let error = Point.red

    static let black = Color(hexCode: "#000000")
    static let black025 = Color(hexCode: "#000000", alpha: 0.25)
    /// 시트 뒤 딤 처리.
    static let scrim = Color(hexCode: "#1A1A1A", alpha: 0.4)

    static let white = Color(hexCode: "#FFFFFF")
    static let white020 = Color(hexCode: "#FFFFFF", alpha: 0.2)
    static let white050 = Color(hexCode: "#FFFFFF", alpha: 0.5)

    static let gray = Gray.gray300
}
