import HackertonCore
import MVICore
import SwiftUI

struct RoutineDetailView: View {
    @ObservedObject private var store: StoreOf<RoutineDetailReducer>
    @State private var deletingCommentID: Int?
    @State private var isDeleteRoutinePresented = false
    @State private var isRoutineMenuPresented = false
    @State private var isCommentsPresented = false
    @State private var feedbackID = UUID()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isCommentFocused: Bool

    init(store: StoreOf<RoutineDetailReducer>) {
        self.store = store
    }

    var body: some View {
        VStack(spacing: 0) {
            AppTopBar(
                store.state.title,
                leading: .asset("CaretLeft", label: "뒤로가기") { dismiss() },
                trailing: .asset("DotsThree", label: "더보기") { isRoutineMenuPresented = true }
            )

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(store.state.steps.enumerated()), id: \.element.id) { index, step in
                            stepCard(step, number: index + 1)
                        }

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: AppSpacing.md) {
                                statistics {
                                    withAnimation { proxy.scrollTo("commentPreviewEnd", anchor: .bottom) }
                                }
                                Spacer(minLength: 0)
                                participateButton
                            }
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                statistics {
                                    withAnimation { proxy.scrollTo("commentPreviewEnd", anchor: .bottom) }
                                }
                                participateButton
                            }
                        }
                        .padding(.top, AppSpacing.xs)
                        .padding(.bottom, AppSpacing.xxs)

                        VStack(spacing: AppSpacing.xxs) {
                            ForEach(Array(store.state.comments.prefix(5))) { comment in
                                commentRow(comment, showsActions: false)
                            }
                        }

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
                        .id("commentPreviewEnd")

                    }
                    .padding(.horizontal, AppSpacing.md)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .confirmationDialog("루틴 관리", isPresented: $isRoutineMenuPresented) {
            if store.state.isOwner {
                Button("삭제하기", role: .destructive) { isDeleteRoutinePresented = true }
            }
            Button("취소", role: .cancel) {}
        }
        .alert("루틴을 정말로 삭제하시겠습니까?", isPresented: $isDeleteRoutinePresented) {
            Button("취소", role: .cancel) {}
            Button("확인", role: .destructive) { store.send(.deleteRoutine) }
        } message: {
            Text("현재는 미리보기 화면만 닫으며 서버 데이터는 삭제하지 않습니다.")
        }
        .onChange(of: store.state.isDeleted) { _, deleted in if deleted { dismiss() } }
        .sheet(isPresented: $isCommentsPresented) {
            commentsSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .background(AppColor.background)
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier(AccessibilityID.RoutineDetail.screen)
        .feedbackPopup(Binding(
            get: {
                store.state.notice.map { FeedbackMessage(id: feedbackID, kind: .info, title: "안내", message: $0) }
            },
            set: { if $0 == nil { store.send(.noticeDismissed) } }
        ))
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
            .aspectRatio(370.0 / 187.0, contentMode: .fit)

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
            Button { store.send(.likeTapped) } label: {
                countLabel("Heart", count: store.state.likeCount)
            }
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

    private func countLabel(_ icon: String, count: Int) -> some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(icon).frame(width: 24, height: 24)
            Text("\(count)")
        }
        .foregroundStyle(AppColor.gray800)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    private var participateButton: some View {
        PrimaryButton(store.state.participation.rawValue) { store.send(.participateTapped) }
            .disabled(store.state.participation == .completed)
            .frame(minWidth: 100, maxWidth: 130)
            .accessibilityIdentifier(AccessibilityID.RoutineDetail.participateButton)
    }

    private func commentRow(_ comment: RoutineDetailReducer.Comment, showsActions: Bool = true) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            avatar
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

    private var commentInput: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            avatar
            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                AppTextField("댓글을 남겨주세요.", text: Binding(
                    get: { store.state.commentDraft },
                    set: { store.send(.commentChanged($0)) }
                ), axis: .vertical, maxLength: 50)
                .focused($isCommentFocused)
                .accessibilityIdentifier(AccessibilityID.RoutineDetail.commentField)

                if store.state.editingCommentID != nil {
                    Button("수정 취소") { store.send(.cancelEditing) }
                        .frame(minHeight: 44)
                }
                if store.state.canSubmitComment {
                    Button(store.state.editingCommentID == nil ? "등록" : "수정 완료") { store.send(.submitCommentTapped) }
                        .font(AppFont.calloutStrong)
                        .foregroundStyle(AppColor.primary)
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityIdentifier(AccessibilityID.RoutineDetail.submitCommentButton)
                }
            }
        }
    }

    private var commentsSheet: some View {
        NavigationStack {
            ScrollViewReader { proxy in
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
                    commentInput
                        .padding(AppSpacing.md)
                        .background(AppColor.background)
                }
                .onChange(of: store.state.comments.count) { _, _ in
                    withAnimation { proxy.scrollTo("commentsBottom", anchor: .bottom) }
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
            .navigationTitle("댓글 \(store.state.commentCount)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") { isCommentsPresented = false }
                }
            }
        }
    }

}

/// Figma 예시 데이터는 Preview·스냅샷에만 사용한다.
enum RoutineDetailPreview {
    static var state: RoutineDetailReducer.State {
        .init(
            title: "김햄찌의 하루",
            steps: (1...2).map {
                .init(
                    id: $0,
                    time: "10:30",
                    title: "아침에 지하철 타러가요",
                    content: "아침에 역시나 사람이 많아요. 지하철 사람들이 모두 회색 인간인 것 같아요. 출근할 때 항상 타는 것인데, 먼가 우울하게 시작하는 것 같아요."
                )
            },
            comments: (1...2).map { .init(id: $0, nickname: "닉네임", dateText: "날짜 및 시간", content: "댓글") },
            likeCount: 10,
            commentCount: 9,
            participatingCount: 3,
            completedCount: 10
        )
    }
}

#Preview("루틴 상세") {
    RoutineDetailView(store: StoreOf<RoutineDetailReducer>(
        state: RoutineDetailPreview.state,
        reducer: RoutineDetailReducer()
    ))
}
