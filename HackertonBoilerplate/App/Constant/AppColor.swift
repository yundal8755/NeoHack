import SwiftUI

enum AppColor {
    enum Gray {
        static let gray50 = Color(hexCode: "#F1F1F1")
        static let gray100 = Color(hexCode: "#DBDBDB")
        static let gray200 = Color(hexCode: "#BABABA")
        static let gray300 = Color(hexCode: "#9D9D9D")
        static let gray400 = Color(hexCode: "#838383")
        static let gray500 = Color(hexCode: "#6B6B6B")
        static let gray600 = Color(hexCode: "#545454")
        static let gray700 = Color(hexCode: "#3F3F3F")
        static let gray800 = Color(hexCode: "#2C2C2C")
        static let gray900 = Color(hexCode: "#1A1A1A")
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
        static let orange = Color(hexCode: "#FF8453")
        static let yellow = Color(hexCode: "#FEDB7D")
        static let skyBlue = Color(hexCode: "#D7F0FA")
    }

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

    static let background = white
    static let surface = Gray.gray50
    static let surfaceRaised = white
    static let primary = Secondary.secondary500
    static let primarySoft = Secondary.secondary50
    static let accent = Point.orange
    static let accentSoft = Point.yellow
    static let ink = textPrimary
    static let textSecondary = Gray.gray500
    static let textTertiary = Gray.gray300
    static let border = Gray.gray100
    static let success = Secondary.secondary500
    static let warning = Point.orange
    static let error = Point.red

    static let textPrimary = Color(hexCode: "#222222")

    static let black = Color(hexCode: "#000000")
    static let black025 = Color(hexCode: "#000000", alpha: 0.25)

    static let white = Color(hexCode: "#FFFFFF")
    static let white020 = Color(hexCode: "#FFFFFF", alpha: 0.2)
    static let white050 = Color(hexCode: "#FFFFFF", alpha: 0.5)

    static let gray = Gray.gray300
}
