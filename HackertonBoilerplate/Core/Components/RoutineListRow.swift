import HackertonCore
import SwiftUI

struct RoutineListRow: View {
    let routine: HomeReducer.Routine
    var showsParticipation = true

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: AppSpacing.xs) {
                    ProfileAvatar(url: routine.avatarURL, size: 35)
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
                            authorName(routine.nickname)
                            if let date = routine.createdAt { createdDate(date) }
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                            authorName(routine.nickname).lineLimit(1)
                            if let date = routine.createdAt {
                                createdDate(date)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                            }
                        }
                    }
                }
                .padding(.vertical, AppSpacing.xxs)

                VStack(alignment: .leading, spacing: 0) {
                    Text(routine.detail.title)
                        .appFont(AppFont.body1)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                        .padding(.vertical, AppSpacing.xxxs)
                    Text(routine.introduction)
                        .appFont(AppFont.caption1)
                        .foregroundStyle(AppColor.gray600)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, AppSpacing.xxxs)
                }
                .padding(.vertical, AppSpacing.xxs)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppSpacing.buttonPadding) {
                        routineCounts(routine)
                        participationBadge(routine.detail.participation)
                    }
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        routineCounts(routine)
                        participationBadge(routine.detail.participation)
                    }
                }
                .padding(.vertical, AppSpacing.xxs)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Group {
                if let url = routine.thumbnailURL ?? routine.detail.steps.first?.imageURL {
                    NetworkImageView(
                        url: url, cornerRadius: AppRadius.button,
                        downsamplingSize: CGSize(width: 115, height: 115 * 9.0 / 16.0),
                        accessibilityLabel: "루틴 대표 이미지", borderColor: nil, showsLoadingText: false
                    )
                } else {
                    RoundedRectangle(cornerRadius: AppRadius.button).fill(AppColor.gray400)
                }
            }
            .frame(width: 115, height: 115 * 9.0 / 16.0)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
        }
        .padding(.vertical, AppSpacing.md)
        .contentShape(Rectangle())
    }

    private func authorName(_ name: String) -> some View {
        Text(name).appFont(AppFont.body2).foregroundStyle(AppColor.grayBlack)
    }

    private func createdDate(_ date: Date?) -> some View {
        Text(date.map(Self.dateFormatter.string(from:)) ?? "")
            .appFont(AppFont.caption2)
            .foregroundStyle(AppColor.gray500)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy. MM. dd HH:mm"
        return formatter
    }()

    private func routineCounts(_ routine: HomeReducer.Routine) -> some View {
        HStack(spacing: AppSpacing.buttonPadding) {
            count(routine.detail.isLiked ? "HomeHeartFilled" : "Heart", value: routine.detail.likeCount)
            if let count = routine.participantCount {
                self.count("User", value: count)
            } else if !routine.isServerRow {
                count("ChatCircle", value: routine.detail.commentCount)
            }
        }
    }

    @ViewBuilder
    private func participationBadge(_ participation: RoutineDetailReducer.Participation) -> some View {
        if showsParticipation && participation != .notJoined {
            Text(participation.rawValue)
                .appFont(AppFont.caption1.weight(.medium))
                .foregroundStyle(participation == .joined ? Color(hexCode: "#3C771B") : AppColor.gray500)
                .padding(.horizontal, AppSpacing.buttonPadding)
                .padding(.vertical, AppSpacing.xxxs)
                .background(participation == .joined ? Color(hexCode: "#D3FBBB") : AppColor.surface, in: Capsule())
                .fixedSize()
        }
    }

    private func count(_ asset: String, value: Int) -> some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(asset).frame(width: 24, height: 24)
            Text("\(value)").appFont(AppFont.caption1)
        }
        .foregroundStyle(AppColor.gray800)
    }
}
