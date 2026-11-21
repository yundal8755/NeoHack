import SwiftUI
import UIKit

/// Figma `너디터리 해커톤` 파일의 텍스트 스타일과 같은 이름·값을 쓴다.
/// 모든 스타일은 Pretendard, 행간 1.5, 자간 0이다.
///
/// 줄 높이까지 Figma와 맞추려면 `Text`에 `.appFont(AppFont.title1)`처럼 스타일을 적용한다.
/// `TextField`나 버튼 라벨처럼 `Font`만 필요한 곳은 `AppFont.title1.font`를 쓴다.
enum AppFont {
    // MARK: - Figma 텍스트 스타일

    /// Title/Title1: SemiBold 22
    static let title1 = AppTextStyle(.semiBold, size: 22, relativeTo: .title2)
    /// Body/Body1: SemiBold 18
    static let body1 = AppTextStyle(.semiBold, size: 18, relativeTo: .headline)
    /// Body/Body2: SemiBold 16
    static let body2 = AppTextStyle(.semiBold, size: 16, relativeTo: .body)
    /// Caption/Caption1: Regular 14
    static let caption1 = AppTextStyle(.regular, size: 14, relativeTo: .subheadline)
    /// Caption/Caption2: Regular 12
    static let caption2 = AppTextStyle(.regular, size: 12, relativeTo: .caption)

    // MARK: - 기존 컴포넌트용 별칭

    static let display = title1.font
    static let hero = title1.font
    static let title = title1.font
    static let title2 = body1.font
    static let headline = body1.font
    static let body = regular(16, relativeTo: .body)
    static let bodyStrong = body2.font
    static let callout = caption1.font
    static let calloutStrong = semiBold(14, relativeTo: .subheadline)
    static let caption = caption2.font
    static let caption2Font = regular(10, relativeTo: .caption2)

    // MARK: - 굵기별 Font

    static func black(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        AppFontWeight.black.font(size: size, relativeTo: textStyle)
    }

    static func extraBold(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        AppFontWeight.extraBold.font(size: size, relativeTo: textStyle)
    }

    static func bold(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        AppFontWeight.bold.font(size: size, relativeTo: textStyle)
    }

    static func semiBold(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        AppFontWeight.semiBold.font(size: size, relativeTo: textStyle)
    }

    static func medium(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        AppFontWeight.medium.font(size: size, relativeTo: textStyle)
    }

    static func regular(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        AppFontWeight.regular.font(size: size, relativeTo: textStyle)
    }

    static func light(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        AppFontWeight.light.font(size: size, relativeTo: textStyle)
    }

    static func extraLight(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        AppFontWeight.extraLight.font(size: size, relativeTo: textStyle)
    }

    static func thin(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        AppFontWeight.thin.font(size: size, relativeTo: textStyle)
    }
}

/// 굵기·크기·행간·자간을 묶은 텍스트 스타일.
/// Figma에 없는 굵기 변형이 필요하면 `AppFont.body2.weight(.medium)`처럼 만든다.
struct AppTextStyle {
    let weight: AppFontWeight
    let size: CGFloat
    let textStyle: Font.TextStyle
    let lineHeightMultiple: CGFloat
    let letterSpacing: CGFloat

    init(
        _ weight: AppFontWeight,
        size: CGFloat,
        relativeTo textStyle: Font.TextStyle = .body,
        lineHeightMultiple: CGFloat = 1.5,
        letterSpacing: CGFloat = 0
    ) {
        self.weight = weight
        self.size = size
        self.textStyle = textStyle
        self.lineHeightMultiple = lineHeightMultiple
        self.letterSpacing = letterSpacing
    }

    var font: Font {
        weight.font(size: size, relativeTo: textStyle)
    }

    /// Figma 줄 높이(size × 행간).
    var lineHeight: CGFloat {
        size * lineHeightMultiple
    }

    /// Figma 줄 높이(size × 행간)와 폰트 고유 줄 높이의 차이.
    var extraLineSpacing: CGFloat {
        let fontLineHeight = UIFont(name: weight.fontName, size: size)?.lineHeight ?? size
        return max(lineHeight - fontLineHeight, 0)
    }

    func weight(_ weight: AppFontWeight) -> AppTextStyle {
        AppTextStyle(
            weight,
            size: size,
            relativeTo: textStyle,
            lineHeightMultiple: lineHeightMultiple,
            letterSpacing: letterSpacing
        )
    }
}

extension View {
    /// 폰트와 함께 Figma 줄 높이를 적용한다. 한 줄 텍스트도 위아래 여백으로 같은 높이를 갖는다.
    func appFont(_ style: AppTextStyle) -> some View {
        let extra = style.extraLineSpacing
        return self
            .font(style.font)
            .tracking(style.letterSpacing)
            .lineSpacing(extra)
            .padding(.vertical, extra / 2)
    }
}

enum AppFontWeight {
    case black
    case extraBold
    case bold
    case semiBold
    case medium
    case regular
    case light
    case extraLight
    case thin

    func font(size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        Font.custom(fontName, size: size, relativeTo: textStyle)
    }

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
