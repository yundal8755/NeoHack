import RoufCore
import MVICore
import SwiftUI

struct RoutineParticipantsDestination: View {
    @StateObject private var store: StoreOf<RoutineParticipantsReducer>
    let routineID: String
    let title: String
    let session: ProfileSession
    let onBack: () -> Void

    init(routineID: String, title: String, session: ProfileSession, onBack: @escaping () -> Void) {
        self.routineID = routineID
        self.title = title
        self.session = session
        self.onBack = onBack
        _store = StateObject(wrappedValue: StoreOf<RoutineParticipantsReducer>(state: .init(),
            reducer: RoutineParticipantsReducer(routineID: routineID, repository: session.repositories.routines)))
    }

    var body: some View {
        RoutineParticipantsView(store: store, routineID: routineID, title: title, session: session, onBack: onBack)
    }
}

struct RoutineParticipantsView: View {
    @ObservedObject var store: StoreOf<RoutineParticipantsReducer>
    let routineID: String
    let title: String
    let session: ProfileSession
    let onBack: () -> Void
    @State private var selectedParticipantID: String?

    var body: some View {
        VStack(spacing: 0) {
            AppTopBar(title, leading: .asset("CaretLeft", label: "뒤로가기", action: onBack))
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if store.state.loaded {
                        (Text("\(store.state.totalCount)명").foregroundColor(AppColor.primary)
                         + Text("이 함께하고 있어요").foregroundColor(AppColor.textPrimary))
                            .appFont(AppFont.body2)
                            .padding(.vertical, AppSpacing.xs)
                    }
                    if store.state.isLoading && !store.state.loaded {
                        ProgressView().frame(maxWidth: .infinity).padding(AppSpacing.lg)
                    } else if let error = store.state.error {
                        ErrorView(title: "참여 목록을 불러오지 못했어요", message: error, retryTitle: "다시 시도") {
                            store.send(.refresh)
                        }
                    } else if store.state.loaded && store.state.rows.isEmpty {
                        EmptyView(title: "아직 함께한 사람이 없어요", message: "첫 참여 기록을 남겨보세요.")
                            .frame(maxWidth: .infinity).padding(.vertical, AppSpacing.lg)
                    }
                    ForEach(store.state.rows) { row in
                        Button {
                            guard selectedParticipantID == nil else { return }
                            selectedParticipantID = row.id
                        } label: {
                            participantRow(row.summary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(AccessibilityID.RoutineParticipants.row(row.id))
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
            .refreshable {
                store.send(.refresh)
                while store.state.isLoading && !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(50))
                }
            }
        }
        .background(AppColor.background)
        .toolbar(.hidden, for: .navigationBar)
        .swipeBack(isEnabled: selectedParticipantID == nil, action: onBack)
        .task { store.send(.appeared) }
        .accessibilityIdentifier(AccessibilityID.RoutineParticipants.screen)
        .navigationDestination(isPresented: Binding(
            get: { selectedParticipantID != nil },
            set: { if !$0 { selectedParticipantID = nil } }
        )) {
            if let participantID = selectedParticipantID {
                RoutineDetailDestination(id: routineID, session: session, resultParticipantID: participantID,
                    onBack: { selectedParticipantID = nil }, onDelete: {
                        selectedParticipantID = nil
                        store.send(.refresh)
                    })
                    .id(participantID)
            }
        }
    }

    private func participantRow(_ summary: RoutineParticipationResults.Summary) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.xs) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.xs) {
                    ProfileAvatar(url: summary.participant?.profileImageURL, size: 31)
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
                            Text(summary.participant?.nickname ?? "").appFont(AppFont.caption1.weight(.semiBold))
                            dateLabel(summary.completedAt)
                        }.fixedSize(horizontal: true, vertical: false)
                        VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                            Text(summary.participant?.nickname ?? "").appFont(AppFont.caption1.weight(.semiBold)).lineLimit(1)
                            dateLabel(summary.completedAt).lineLimit(1).minimumScaleFactor(0.8)
                        }
                    }
                }
                Text(summary.title ?? "참여 기록").appFont(AppFont.body2).lineLimit(1)
                if let content = summary.content, !content.isEmpty {
                    Text(content).appFont(AppFont.caption2).foregroundStyle(AppColor.gray600).lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            NetworkImageView(url: summary.thumbnailURL, cornerRadius: AppRadius.button,
                             downsamplingSize: CGSize(width: 147, height: 147 * 9.0 / 16.0),
                             accessibilityLabel: "참여 기록 대표 사진", borderColor: nil, showsLoadingText: false)
                .frame(width: 147, height: 147 * 9.0 / 16.0)
        }
        .foregroundStyle(AppColor.textPrimary)
        .padding(.vertical, AppSpacing.md)
        .contentShape(Rectangle())
    }

    private func dateLabel(_ date: Date?) -> some View {
        Text(date.map(Self.dateFormatter.string(from:)) ?? "")
            .appFont(AppFont.caption2).foregroundStyle(AppColor.gray500)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter
    }()
}
