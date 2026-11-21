import SwiftUI
import Kingfisher

struct NetworkImageView: View {
    private let url: URL?
    private let contentMode: SwiftUI.ContentMode
    private let cornerRadius: CGFloat
    private let downsamplingSize: CGSize?
    private let accessibilityLabel: String
    private let borderColor: Color?
    private let showsLoadingText: Bool
    private let authorizationToken: String?
    private let cachesOriginalImage: Bool

    @Environment(\.displayScale) private var displayScale

    init(
        url: URL?,
        contentMode: SwiftUI.ContentMode = .fill,
        cornerRadius: CGFloat = AppRadius.medium,
        downsamplingSize: CGSize? = nil,
        accessibilityLabel: String = "Network image",
        borderColor: Color? = AppColor.border,
        showsLoadingText: Bool = true,
        authorizationToken: String? = nil,
        cachesOriginalImage: Bool = true
    ) {
        self.url = url
        self.contentMode = contentMode
        self.cornerRadius = cornerRadius
        self.downsamplingSize = downsamplingSize
        self.accessibilityLabel = accessibilityLabel
        self.borderColor = borderColor
        self.showsLoadingText = showsLoadingText
        self.authorizationToken = authorizationToken
        self.cachesOriginalImage = cachesOriginalImage
    }

    init(
        urlString: String?,
        contentMode: SwiftUI.ContentMode = .fill,
        cornerRadius: CGFloat = AppRadius.medium,
        downsamplingSize: CGSize? = nil,
        accessibilityLabel: String = "Network image",
        borderColor: Color? = AppColor.border,
        showsLoadingText: Bool = true,
        authorizationToken: String? = nil,
        cachesOriginalImage: Bool = true
    ) {
        self.init(
            url: urlString.flatMap(URL.init(string:)),
            contentMode: contentMode,
            cornerRadius: cornerRadius,
            downsamplingSize: downsamplingSize,
            accessibilityLabel: accessibilityLabel,
            borderColor: borderColor,
            showsLoadingText: showsLoadingText,
            authorizationToken: authorizationToken,
            cachesOriginalImage: cachesOriginalImage
        )
    }

    var body: some View {
        Group {
            if let url {
                remoteImage(url)
            } else {
                failurePlaceholder
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            if let borderColor {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: accessibilityLabel))
    }

    private func remoteImage(_ url: URL) -> some View {
        var image = KFImage.url(url)
            .placeholder {
                loadingPlaceholder
            }
            .onFailureView {
                failurePlaceholder
            }
            .resizable()
            .fade(duration: 0.2)
            .cancelOnDisappear(true)

        if cachesOriginalImage {
            image = image.cacheOriginalImage()
        }

        if let authorizationToken, authorizationToken.isEmpty == false {
            image = image.requestModifier(AnyModifier { request in
                var request = request
                request.setValue("Bearer \(authorizationToken)", forHTTPHeaderField: "Authorization")
                return request
            })
        }

        if let downsamplingSize {
            // downsamplingSize는 포인트 단위다. Kingfisher는 scaleFactor(기본 1)를 곱해 픽셀 크기를 정하므로
            // 화면 배율을 넘겨야 2x·3x 기기에서 흐려지지 않는다.
            image = image
                .downsampling(size: downsamplingSize)
                .scaleFactor(displayScale)
        }

        return image
            .aspectRatio(contentMode: contentMode)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
    }

    @ViewBuilder
    private var loadingPlaceholder: some View {
        if showsLoadingText {
            VStack(spacing: AppSpacing.xs) {
                ProgressView()
                    .tint(AppColor.primary)

                Text(verbatim: "Loading image")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(AppSpacing.md)
            .background(AppColor.surfaceRaised)
        } else {
            skeletonPlaceholder
        }
    }

    /// 이미지를 받는 동안 보이는 스켈레톤. 모서리는 바깥의 clipShape가 맞춘다.
    private var skeletonPlaceholder: some View {
        AppColor.gray100
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .shimmer()
    }

    @ViewBuilder
    private var failurePlaceholder: some View {
        if showsLoadingText {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: "photo.fill")
                    .font(.system(size: AppSpacing.lg, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColor.accent)
                    .frame(width: AppSpacing.xl, height: AppSpacing.xl)
                    .background(AppColor.accentSoft)
                    .clipShape(Circle())

                Text(verbatim: "Image unavailable")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(AppSpacing.md)
            .background(AppColor.surfaceRaised)
        } else {
            compactImagePlaceholder
        }
    }

    private var compactImagePlaceholder: some View {
        ZStack {
            AppColor.gray50

            Image(systemName: "photo.fill")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(AppColor.gray300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
