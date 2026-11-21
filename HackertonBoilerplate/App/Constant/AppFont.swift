import SwiftUI

enum AppFont {
    static let display = heading1
    static let hero = heading1
    static let title = heading1
    static let title2 = heading2
    static let headline = headline2
    static let body = body1Regular
    static let bodyStrong = body1Medium
    static let callout = body2Regular
    static let calloutStrong = body2Semibold
    static let caption = caption2Medium
    static let caption2 = caption3Regular

    static let heading1 = bold(22, relativeTo: .title2)
    static let heading2 = bold(20, relativeTo: .title3)
    static let headline1 = bold(18, relativeTo: .headline)
    static let headline2 = bold(17, relativeTo: .headline)
    static let price1Bold = bold(16, relativeTo: .body)
    static let price2Bold = bold(14, relativeTo: .subheadline)
    static let body1Semibold = semiBold(16, relativeTo: .body)
    static let body1Medium = medium(16, relativeTo: .body)
    static let body1Regular = regular(16, relativeTo: .body)
    static let body2Semibold = semiBold(15, relativeTo: .callout)
    static let body2Medium = medium(15, relativeTo: .callout)
    static let body2Regular = regular(15, relativeTo: .callout)
    static let body3Semibold = semiBold(14, relativeTo: .subheadline)
    static let body3Medium = medium(14, relativeTo: .subheadline)
    static let body3Regular = regular(14, relativeTo: .subheadline)
    static let caption1Semibold = semiBold(13, relativeTo: .caption)
    static let caption1Medium = medium(13, relativeTo: .caption)
    static let caption1Regular = regular(13, relativeTo: .caption)
    static let caption2Semibold = semiBold(12, relativeTo: .caption2)
    static let caption2Medium = medium(12, relativeTo: .caption2)
    static let caption2Regular = regular(12, relativeTo: .caption2)
    static let caption3Semibold = semiBold(10, relativeTo: .caption2)
    static let caption3Medium = medium(10, relativeTo: .caption2)
    static let caption3Regular = regular(10, relativeTo: .caption2)

    static let heading1Style = textStyle(.bold, size: 22, relativeTo: .title2)
    static let heading2Style = textStyle(.bold, size: 20, relativeTo: .title3)
    static let headline1Style = textStyle(.bold, size: 18, relativeTo: .headline)
    static let headline2Style = textStyle(.bold, size: 17, relativeTo: .headline)
    static let price1BoldStyle = textStyle(.bold, size: 16, relativeTo: .body)
    static let price2BoldStyle = textStyle(.bold, size: 14, relativeTo: .subheadline)
    static let body1SemiboldStyle = textStyle(.semiBold, size: 16, relativeTo: .body)
    static let body1MediumStyle = textStyle(.medium, size: 16, relativeTo: .body)
    static let body1RegularStyle = textStyle(.regular, size: 16, relativeTo: .body)
    static let body2SemiboldStyle = textStyle(.semiBold, size: 15, relativeTo: .callout)
    static let body2MediumStyle = textStyle(.medium, size: 15, relativeTo: .callout)
    static let body2RegularStyle = textStyle(.regular, size: 15, relativeTo: .callout)
    static let body3SemiboldStyle = textStyle(.semiBold, size: 14, relativeTo: .subheadline)
    static let body3MediumStyle = textStyle(.medium, size: 14, relativeTo: .subheadline)
    static let body3RegularStyle = textStyle(.regular, size: 14, relativeTo: .subheadline)
    static let caption1SemiboldStyle = textStyle(.semiBold, size: 13, relativeTo: .caption)
    static let caption1MediumStyle = textStyle(.medium, size: 13, relativeTo: .caption)
    static let caption1RegularStyle = textStyle(.regular, size: 13, relativeTo: .caption)
    static let caption2SemiboldStyle = textStyle(.semiBold, size: 12, relativeTo: .caption2)
    static let caption2MediumStyle = textStyle(.medium, size: 12, relativeTo: .caption2)
    static let caption2RegularStyle = textStyle(.regular, size: 12, relativeTo: .caption2)
    static let caption3SemiboldStyle = textStyle(.semiBold, size: 10, relativeTo: .caption2)
    static let caption3MediumStyle = textStyle(.medium, size: 10, relativeTo: .caption2)
    static let caption3RegularStyle = textStyle(.regular, size: 10, relativeTo: .caption2)

    static func black(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        pretendard(.black, size: size, relativeTo: textStyle)
    }

    static func extraBold(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        pretendard(.extraBold, size: size, relativeTo: textStyle)
    }

    static func bold(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        pretendard(.bold, size: size, relativeTo: textStyle)
    }

    static func semiBold(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        pretendard(.semiBold, size: size, relativeTo: textStyle)
    }

    static func medium(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        pretendard(.medium, size: size, relativeTo: textStyle)
    }

    static func regular(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        pretendard(.regular, size: size, relativeTo: textStyle)
    }

    static func light(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        pretendard(.light, size: size, relativeTo: textStyle)
    }

    static func extraLight(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        pretendard(.extraLight, size: size, relativeTo: textStyle)
    }

    static func thin(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        pretendard(.thin, size: size, relativeTo: textStyle)
    }

    private static func pretendard(
        _ weight: PretendardWeight,
        size: CGFloat,
        relativeTo textStyle: Font.TextStyle
    ) -> Font {
        Font.custom(weight.fontName, size: size, relativeTo: textStyle)
    }

    private static func textStyle(
        _ weight: PretendardWeight,
        size: CGFloat,
        relativeTo textStyle: Font.TextStyle
    ) -> AppTextStyle {
        AppTextStyle(
            font: pretendard(weight, size: size, relativeTo: textStyle),
            size: size,
            lineHeightMultiple: 1.3,
            letterSpacingRatio: -0.02
        )
    }
}

struct AppTextStyle {
    let font: Font
    let size: CGFloat
    let lineHeightMultiple: CGFloat
    let letterSpacingRatio: CGFloat

    var lineSpacing: CGFloat {
        max((size * lineHeightMultiple) - size, 0)
    }

    var letterSpacing: CGFloat {
        size * letterSpacingRatio
    }
}

extension View {
    func appFont(_ style: AppTextStyle) -> some View {
        self
            .font(style.font)
            .tracking(style.letterSpacing)
            .lineSpacing(style.lineSpacing)
    }
}

private enum PretendardWeight {
    case black
    case extraBold
    case bold
    case semiBold
    case medium
    case regular
    case light
    case extraLight
    case thin

    var fontName: String {
        switch self {
        case .black:
            "Pretendard-Black"
        case .extraBold:
            "Pretendard-ExtraBold"
        case .bold:
            "Pretendard-Bold"
        case .semiBold:
            "Pretendard-SemiBold"
        case .medium:
            "Pretendard-Medium"
        case .regular:
            "Pretendard-Regular"
        case .light:
            "Pretendard-Light"
        case .extraLight:
            "Pretendard-ExtraLight"
        case .thin:
            "Pretendard-Thin"
        }
    }
}
