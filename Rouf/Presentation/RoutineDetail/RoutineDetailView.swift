import RoufCore
import MVICore
import SwiftUI

struct RoutineDetailView: View {
    @ObservedObject private var store: StoreOf<RoutineDetailReducer>
    @State private var deletingCommentID: String?
    @State private var isDeleteRoutinePresented = false
    @State private var isRoutineMenuPresented = false
    @State private var isParticipantsPresented = false
    @State private var isCommentsPresented = false
    @State private var isParticipationPresented = false
    private let session: ProfileSession?
    private let routineID: String?
    private let resultParticipantID: String?
    private let onUpdated: () -> Void
    @State private var isEditPresented = false
    @State private var selectedProfile: ProfileRoute?

    private struct ProfileRoute: Identifiable, Hashable {
        let id: String
    }
    private let onParticipationCompleted: () -> Void
    @State private var feedbackID = UUID()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isCommentFocused: Bool

    private let onBack: (() -> Void)?
    private let onDelete: () -> Void

    init(store: StoreOf<RoutineDetailReducer>, session: ProfileSession? = nil, routineID: String? = nil, resultParticipantID: String? = nil, onParticipationCompleted: @escaping () -> Void = {}, onUpdated: @escaping () -> Void = {}, onBack: (() -> Void)? = nil, onDelete: @escaping () -> Void = {}) {
        self.store = store
        self.session = session
        self.routineID = routineID
        self.resultParticipantID = resultParticipantID
        self.onUpdated = onUpdated
        self.onParticipationCompleted = onParticipationCompleted
        self.onBack = onBack
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(spacing: 0) {
            AppTopBar(
                store.state.navigationTitle,
                leading: .asset("CaretLeft", label: "뒤로가기") { closeDetail() },
                trailing: store.state.showsMoreMenu
                    ? .asset("DotsThree", label: "더보기", isEnabled: !store.state.isBusy) {
                        isRoutineMenuPresented.toggle()
                    }
                    : nil
            )
            .overlay(alignment: .topTrailing) {
                if isRoutineMenuPresented {
                    VStack(spacing: 0) {
                        if session != nil, store.state.canEdit {
                            Button {
                                isRoutineMenuPresented = false
                                isEditPresented = true
                            } label: {
                                menuLabel(store.state.isParticipationResult ? "참여 기록 수정" : "수정하기")
                            }
                            .accessibilityIdentifier(AccessibilityID.RoutineDetail.editButton)
                        }
                        Button(role: .destructive) {
                            isRoutineMenuPresented = false
                            isDeleteRoutinePresented = true
                        } label: {
                            menuLabel(store.state.isParticipationResult ? "참여 기록 삭제" : "삭제하기")
                                .foregroundStyle(.red)
                        }
                    }
                    .buttonStyle(.plain)
                    .background(AppColor.background, in: RoundedRectangle(cornerRadius: AppRadius.button))
                    .shadow(color: AppColor.black.opacity(0.12), radius: 8, y: 3)
                    .padding(.trailing, AppSpacing.md)
                    .offset(y: 44)
                }
            }
            .zIndex(1)

            if store.state.isLive && !store.state.loaded {
                if let message = store.state.loadError {
                    ErrorView(title: "루틴을 불러오지 못했어요", message: message, retryTitle: "다시 시도") { store.send(.load) }
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            detailHeader
                            ForEach(Array(store.state.steps.enumerated()), id: \.element.id) { index, step in
                                stepCard(step, number: index + 1)
                            }

                            if !store.state.isParticipationResult {
                                ViewThatFits(in: .horizontal) {
                                    HStack(spacing: AppSpacing.md) {
                                        statistics {
                                            withAnimation { proxy.scrollTo("commentPreviewEnd", anchor: .bottom) }
                                        }
                                        Spacer(minLength: 0)
                                        participateButton
                                            .frame(width: 130)
                                    }
                                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                        statistics {
                                            withAnimation { proxy.scrollTo("commentPreviewEnd", anchor: .bottom) }
                                        }
                                        participateButton
                                            .frame(width: 130)
                                    }
                                }
                                .padding(.top, AppSpacing.xs)
                                .padding(.bottom, AppSpacing.xxs)

                                VStack(spacing: AppSpacing.xxs) {
                                    ForEach(Array(store.state.comments.prefix(5))) { comment in
                                        commentRow(comment, showsActions: false)
                                    }
                                }

                                if store.state.comments.count >= 5 {
                                    Button {
                                        isCommentsPresented = true
                                    } label: {
                                        Text("댓글 전체보기")
                                            .appFont(AppFont.caption1)
                                            .foregroundStyle(AppColor.textSecondary)
                                            .frame(maxWidth: .infinity, minHeight: 44)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier(AccessibilityID.RoutineDetail.allCommentsButton)
                                    .padding(.bottom, AppSpacing.md)

                                }
                                Color.clear.frame(height: 1).id("commentPreviewEnd")
                            }

                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, store.state.isParticipationResult ? AppSpacing.md : 65 + AppSpacing.md)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: store.state.comments.count) { _, _ in
                        if isCommentFocused && !isCommentsPresented {
                            withAnimation { proxy.scrollTo("commentPreviewEnd", anchor: .bottom) }
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !store.state.isParticipationResult, !isCommentsPresented,
               store.state.loaded || !store.state.isLive {
                commentBar
                    .overlay(alignment: .topTrailing) {
                        if session != nil {
                            Button {
                                isCommentFocused = false
                                isParticipantsPresented = true
                            } label: {
                                Image("ParticipantsButton").frame(width: 65, height: 65)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("함께한 사람들 보기")
                            .accessibilityIdentifier(AccessibilityID.RoutineDetail.participantsButton)
                            .padding(.trailing, AppSpacing.md)
                            .offset(y: -(65 + AppSpacing.md))
                        }
                    }
            }
        }
        .navigationDestination(isPresented: $isParticipantsPresented) {
            if let session, let routineID {
                RoutineParticipantsDestination(routineID: routineID, title: store.state.title, session: session) {
                    isParticipantsPresented = false
                    store.send(.load)
                }
            }
        }
        .task { if !store.state.loaded { store.send(.load) } }
        .alert(store.state.isParticipationResult ? "참여 기록을 삭제하시겠습니까?" : "루틴을 정말로 삭제하시겠습니까?", isPresented: $isDeleteRoutinePresented) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                store.send(store.state.isParticipationResult ? .deleteParticipationResult : .deleteRoutine)
            }
        } message: {
            Text(store.state.isParticipationResult
                 ? "작성한 참여 기록은 복구할 수 없어요. 원본 루틴은 유지됩니다."
                 : "삭제한 루틴은 목록에서 사라집니다.")
        }
        .onChange(of: store.state.isDeleted) { _, deleted in
            if deleted {
                onDelete()
                closeDetail()
            }
        }
        .fullScreenCover(isPresented: $isParticipationPresented, onDismiss: {
            if store.state.participation == .completed {
                onParticipationCompleted()
            } else { store.send(.load) }
        }) {
            if let session, let routineID {
                RoutineParticipationView(routineID: routineID, steps: store.state.steps,
                                         participation: store.state.participation, repositories: session.repositories) {
                    store.send(.interactionUpdated($0))
                    isParticipationPresented = false
                } onCancel: {
                    isParticipationPresented = false
                } onDraftSaved: {
                    isParticipationPresented = false
                }
            }
        }
        .fullScreenCover(isPresented: $isEditPresented) {
            if let session, let routineID, let entity = store.state.entity {
                RoutineEditView(
                    detail: entity,
                    target: resultParticipantID.map { .participation(routineID: routineID, participantID: $0) }
                        ?? .routine(id: routineID),
                    repositories: session.repositories,
                    onSaved: {
                        isEditPresented = false
                        store.send(.load)
                        onUpdated()
                    },
                    onCancel: { isEditPresented = false })
            }
        }
        .navigationDestination(item: $selectedProfile) { profile in
            if let session {
                PublicProfileView(publicID: profile.id, users: session.repositories.users, session: session, onBack: {
                    selectedProfile = nil
                    store.send(.load)
                })
            }
        }
        .sheet(isPresented: $isCommentsPresented) {
            commentsSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(AppColor.background)
                .preferredColorScheme(.light)
        }
        .background(AppColor.background)
        .toolbar(.hidden, for: .navigationBar)
        .swipeBack(
            isEnabled: !store.state.isBusy && !isCommentsPresented && !isEditPresented
                && !isParticipationPresented && selectedProfile == nil
                && !isParticipantsPresented && !isDeleteRoutinePresented,
            action: closeDetail
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.RoutineDetail.screen)
        .feedbackPopup(Binding(
            get: {
                store.state.notice.map { FeedbackMessage(id: feedbackID, kind: .error, title: "요청을 처리하지 못했어요", message: $0) }
            },
            set: { if $0 == nil { store.send(.noticeDismissed) } }
        ))
    }

    private static let detailDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy. MM. dd. HH:mm"
        return formatter
    }()

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Button {
                guard let owner = store.state.entity?.owner, session != nil else { return }
                selectedProfile = ProfileRoute(id: owner.id)
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    ProfileAvatar(url: store.state.authorImageURL, size: store.state.isParticipationResult ? 35 : 44)
                    Text(store.state.authorNickname ?? "")
                        .appFont(AppFont.body2)
                        .lineLimit(1)
                    Spacer(minLength: AppSpacing.xs)
                    if let date = store.state.createdAt {
                        Text(Self.detailDateFormatter.string(from: date))
                            .appFont(AppFont.caption2)
                            .foregroundStyle(AppColor.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppColor.textPrimary)
            .disabled(session == nil || store.state.entity?.owner == nil)
            .accessibilityLabel("\(store.state.authorNickname ?? "작성자") 프로필 보기")
            .accessibilityIdentifier(AccessibilityID.RoutineDetail.authorProfileButton)
            if store.state.isParticipationResult {
                Text(store.state.title)
                    .appFont(AppFont.body2.weight(.semiBold))
                    .lineLimit(1)
                if let introduction = store.state.introduction, !introduction.isEmpty {
                    Text(introduction)
                        .appFont(AppFont.caption1)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, store.state.isParticipationResult ? AppSpacing.md : 0)
    }

    private func closeDetail() {
        if let onBack { onBack() } else { dismiss() }
    }

    private func stepCard(_ step: RoutineDetailReducer.Step, number: Int) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Step\(number)")
                .appFont(AppFont.caption2.weight(.semiBold))
                .foregroundStyle(AppColor.primary)

            GeometryReader { geometry in
                if let imageURL = step.imageURL {
                    NetworkImageView(
                        url: imageURL,
                        cornerRadius: AppRadius.button,
                        downsamplingSize: geometry.size,
                        accessibilityLabel: "\(number)단계 이미지",
                        borderColor: nil,
                        showsLoadingText: false
                    )
                } else {
                    RoundedRectangle(cornerRadius: AppRadius.button)
                        .fill(Color(hexCode: "#C7C7C7"))
                        .accessibilityLabel("\(number)단계 이미지 없음")
                }
            }
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    Text(step.time)
                        .foregroundStyle(AppColor.grayBlack)
                        .fixedSize()
                    Text(step.title)
                        .foregroundStyle(AppColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .appFont(AppFont.body2)

                Text(step.content)
                    .appFont(AppTextStyle(.regular, size: 13, relativeTo: .footnote))
                    .foregroundStyle(AppColor.gray800)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, AppSpacing.md)
    }

    private func statistics(onComments: @escaping () -> Void) -> some View {
        HStack(spacing: AppSpacing.buttonPadding) {
            Button {
                HapticFeedbackManager.shared.impact(style: store.state.isLiked ? .light : .medium)
                store.send(.likeTapped)
            } label: {
                countLabel(store.state.isLiked && store.state.isLive ? "HomeHeartFilled" : "Heart", count: store.state.likeCount)
            }
            .disabled(store.state.isBusy)
            .accessibilityLabel("좋아요 \(store.state.likeCount)개")
            .accessibilityIdentifier(AccessibilityID.RoutineDetail.likeButton)

            Button(action: onComments) {
                countLabel("ChatCircle", count: store.state.commentCount)
            }
            .accessibilityLabel("댓글 \(store.state.commentCount)개로 이동")
            .accessibilityIdentifier(AccessibilityID.RoutineDetail.commentsButton)

            Text("참여중 \(store.state.participatingCount)")
                .foregroundStyle(AppColor.primary)
            Text("참여 완료 \(store.state.completedCount)")
                .foregroundStyle(AppColor.gray500)
        }
        .appFont(AppFont.caption1.weight(.medium))
        .fixedSize(horizontal: true, vertical: false)
        .buttonStyle(.plain)
    }

    private func menuLabel(_ title: String) -> some View {
        Text(title)
            .appFont(AppFont.caption1)
            .frame(minWidth: 130, minHeight: 44)
            .padding(.horizontal, AppSpacing.sm)
            .contentShape(Rectangle())
    }

    private func countLabel(_ icon: String, count: Int) -> some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(icon).frame(width: 24, height: 24)
            Text("\(count)")
        }
        .foregroundStyle(AppColor.gray800)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var participateButton: some View {
        if !store.state.isOwner && !store.state.isParticipationResult {
            VStack(spacing: AppSpacing.xxs) {
                PrimaryButton(store.state.participation == .joined ? "이어서 작성" : store.state.participation.rawValue) {
                    if session != nil { isParticipationPresented = true }
                    else { store.send(.participateTapped) }
                }
                .disabled(store.state.participation == .completed || store.state.isBusy || store.state.steps.isEmpty)
                .accessibilityIdentifier(AccessibilityID.RoutineDetail.participateButton)
                if store.state.participation == .joined {
                    PrimaryButton("참여 취소", style: .secondary) { store.send(.leaveTapped) }
                        .disabled(store.state.isBusy)
                }
            }
        }
    }

    private func commentRow(_ comment: RoutineDetailReducer.Comment, showsActions: Bool = true) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            ProfileAvatar(url: comment.avatarURL, size: 41)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppSpacing.xs) {
                        nickname(comment.nickname)
                        dateLabel(comment.dateText)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        nickname(comment.nickname)
                        dateLabel(comment.dateText)
                    }
                }
                Text(comment.content)
                    .appFont(AppFont.caption1)
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if comment.isMine && showsActions {
                Menu {
                    Button("수정하기") {
                        store.send(.editComment(comment.id))
                        isCommentFocused = true
                    }
                    Button("삭제하기", role: .destructive) { deletingCommentID = comment.id }
                } label: {
                    Image("DotsThree").frame(width: 44, height: 44)
                }
                .accessibilityLabel("내 댓글 관리")
            }
        }
        .padding(.vertical, AppSpacing.xs)
        .accessibilityElement(children: .combine)
    }

    private func nickname(_ text: String) -> some View {
        Text(text).appFont(AppFont.body2).foregroundStyle(AppColor.grayBlack)
    }

    private func dateLabel(_ text: String) -> some View {
        Text(text).appFont(AppFont.caption2).foregroundStyle(AppColor.gray600)
    }

    private var avatar: some View {
        Image("RoutineDetailAvatar")
            .resizable()
            .frame(width: 41, height: 41)
            .accessibilityHidden(true)
    }

    private var commentBar: some View {
        commentInput
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, AppSpacing.md)
            .background(AppColor.background)
            .overlay(alignment: .top) {
                Rectangle().fill(AppColor.gray200).frame(height: 1)
            }
    }

    private var commentInput: some View {
        HStack(alignment: .center, spacing: AppSpacing.sm) {
            ProfileAvatar(url: session?.profileImageURL, size: 41)
            AppTextField("댓글을 남겨주세요.", text: Binding(
                get: { store.state.commentDraft },
                set: { store.send(.commentChanged($0)) }
            ), maxLength: 50)
            .focused($isCommentFocused)
            .submitLabel(.send)
            .onSubmit {
                if store.state.canSubmitComment && !store.state.isBusy { store.send(.submitCommentTapped) }
            }
            .accessibilityIdentifier(AccessibilityID.RoutineDetail.commentField)

            if store.state.editingCommentID != nil {
                Button { store.send(.cancelEditing) } label: {
                    Image(systemName: "xmark").frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppColor.textSecondary)
                .accessibilityLabel("댓글 수정 취소")
            }
            if store.state.canSubmitComment {
                Button(store.state.editingCommentID == nil ? "등록" : "수정") { store.send(.submitCommentTapped) }
                    .disabled(store.state.isBusy)
                    .buttonStyle(.plain)
                    .font(AppFont.calloutStrong)
                    .foregroundStyle(AppColor.primary)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier(AccessibilityID.RoutineDetail.submitCommentButton)
            }
            if isCommentFocused {
                Button { isCommentFocused = false } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .font(.system(size: 20))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppColor.textSecondary)
                .accessibilityLabel("키보드 내리기")
                .accessibilityIdentifier(AccessibilityID.RoutineDetail.dismissKeyboardButton)
            }
        }
    }

    private var commentsSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack {
                    Text("댓글 \(store.state.commentCount)")
                        .appFont(AppFont.body2.weight(.semiBold))
                        .accessibilityAddTraits(.isHeader)
                    HStack {
                        Spacer()
                        Button {
                            isCommentFocused = false
                            isCommentsPresented = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("댓글 닫기")
                        .accessibilityIdentifier(AccessibilityID.TopBar.trailingButton)
                    }
                }
                .foregroundStyle(AppColor.textPrimary)
                .frame(height: 44)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xs)
                ScrollViewReader { proxy in
                    if #available(iOS 26.0, *) {
                        commentsScroll(proxy: proxy).scrollEdgeEffectHidden()
                    } else {
                        commentsScroll(proxy: proxy)
                    }
                }
            }
            .alert("정말로 댓글을 삭제하시겠습니까?", isPresented: Binding(
                get: { deletingCommentID != nil },
                set: { if !$0 { deletingCommentID = nil } }
            )) {
                Button("취소", role: .cancel) { deletingCommentID = nil }
                Button("확인", role: .destructive) {
                    if let id = deletingCommentID { store.send(.deleteComment(id)) }
                    deletingCommentID = nil
                }
            }
            .background(AppColor.background)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func commentsScroll(proxy: ScrollViewProxy) -> some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.xxs) {
                if store.state.comments.isEmpty {
                    Text("첫 댓글을 남겨보세요.")
                        .foregroundStyle(AppColor.textSecondary)
                        .padding(.vertical, AppSpacing.lg)
                }
                ForEach(store.state.comments) { comment in
                    commentRow(comment).id(comment.id)
                }
                Color.clear.frame(height: 1).id("commentsBottom")
            }
            .padding(.horizontal, AppSpacing.md)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            commentBar
        }
        .onChange(of: store.state.comments.count) { _, _ in
            withAnimation { proxy.scrollTo("commentsBottom", anchor: .bottom) }
        }
        .background(AppColor.background)
    }

}

#if DEBUG
#Preview("루틴 상세") {
    RoutineDetailView(store: StoreOf<RoutineDetailReducer>(
        state: MockRoutineData.detail,
        reducer: RoutineDetailReducer()
    ))
}

#endif
