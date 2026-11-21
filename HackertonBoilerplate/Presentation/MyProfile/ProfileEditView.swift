import HackertonCore
import MVICore
import PhotosUI
import SwiftUI

/// 프로필 편집 화면. 마이 화면에서 push로 열린다.
/// 프로필 사진·닉네임·한 줄 소개를 바꾸고 하단 `저장`으로 반영한다.
struct ProfileEditView: View {
    @ObservedObject var store: StoreOf<MyProfileReducer>
    let imageURL: URL?

    @State private var selection: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isLoadingPhoto = false
    @State private var photoError: String?
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case nickname
        case bio
    }

    init(store: StoreOf<MyProfileReducer>, imageURL: URL? = nil) {
        self.store = store
        self.imageURL = imageURL
    }

    private var state: MyProfileReducer.State { store.state }
    private var nickname: String { state.edit?.nickname ?? "" }
    private var bio: String { state.edit?.bio ?? "" }

    var body: some View {
        VStack(spacing: 0) {
            AppTopBar(
                "프로필 편집",
                leading: .asset("CaretLeft", label: "뒤로 가기", isEnabled: !state.isSaving) {
                    focusedField = nil
                    store.send(.closeEditor)
                })

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    photoPicker
                        .padding(.top, AppSpacing.lg)

                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        nicknameField
                        bioField
                    }

                    if let message = state.editError {
                        Text(verbatim: message)
                            .appFont(AppFont.caption2)
                            .foregroundStyle(AppColor.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.lg)
                .background {
                    // 입력창 밖 빈 곳을 누르면 키보드를 내린다.
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { focusedField = nil }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom, spacing: 0) { saveButton }
        }
        .background(AppColor.background)
        .disabled(state.isSaving)
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.MyProfile.editScreen)
        .alert(
            Text(verbatim: "변경한 내용을 저장하지 않고 나갈까요?"),
            isPresented: Binding(
                get: { state.isDiscardAlertPresented },
                set: { if !$0 { store.send(.discardCancelled) } }
            )
        ) {
            Button(role: .cancel) { store.send(.discardCancelled) } label: { Text(verbatim: "계속 편집") }
            Button(role: .destructive) { store.send(.editorDismissed) } label: { Text(verbatim: "나가기") }
        }
        .onChange(of: selection) { _, item in isLoadingPhoto = item != nil }
        .task(id: selection) { await loadPhoto() }
    }

    // MARK: - 프로필 사진

    private var photoPicker: some View {
        VStack(spacing: AppSpacing.xs) {
            PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
                avatar
                    .overlay(alignment: .bottomTrailing) { cameraBadge }
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(isLoadingPhoto)
            .accessibilityLabel(Text(verbatim: "프로필 사진 변경"))
            .accessibilityIdentifier(AccessibilityID.MyProfile.editPhoto)

            if let photoError {
                Text(verbatim: photoError)
                    .appFont(AppFont.caption2)
                    .foregroundStyle(AppColor.error)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var avatar: some View {
        Group {
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: Self.avatarSize, height: Self.avatarSize)
                    .clipShape(Circle())
                    .accessibilityHidden(true)
            } else if let imageURL {
                ProfileAvatar(url: imageURL, size: Self.avatarSize)
            } else {
                // 마이 화면 헤더와 같은 기본 이미지를 쓴다.
                Image("MyProfileAvatar")
                    .resizable()
                    .frame(width: Self.avatarSize, height: Self.avatarSize)
                    .accessibilityHidden(true)
            }
        }
        .overlay {
            if isLoadingPhoto {
                Circle()
                    .fill(AppColor.scrim)
                    .overlay { ProgressView().tint(AppColor.white) }
            }
        }
    }

    private var cameraBadge: some View {
        Image(systemName: "camera.fill")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppColor.white)
            .frame(width: Self.badgeSize, height: Self.badgeSize)
            .background(AppColor.primary, in: Circle())
            .overlay { Circle().strokeBorder(AppColor.background, lineWidth: 2) }
            .accessibilityHidden(true)
    }

    // MARK: - 입력

    private var nicknameField: some View {
        let range = UserProfileUpdate.nicknameLength
        return FormField(
            "닉네임", guide: "\(range.lowerBound)자에서 \(range.upperBound)자까지 입력해 주세요.", isRequired: true
        ) {
            AppTextField(
                "닉네임을 입력해 주세요.",
                text: Binding(get: { nickname }, set: { store.send(.nicknameChanged($0)) }),
                maxLength: range.upperBound
            )
            .focused($focusedField, equals: .nickname)
            .submitLabel(.next)
            .onSubmit { focusedField = .bio }
            .accessibilityIdentifier(AccessibilityID.MyProfile.editNickname)

            counter(nickname.count, limit: range.upperBound)
        }
    }

    private var bioField: some View {
        let limit = UserProfileUpdate.bioMaxLength
        return FormField("한 줄 소개", guide: "최대 \(limit)자까지 입력 가능해요.") {
            AppTextField(
                "나를 한 줄로 소개해 주세요.",
                text: Binding(get: { bio }, set: { store.send(.bioChanged($0)) }),
                maxLength: limit
            )
            .focused($focusedField, equals: .bio)
            .submitLabel(.done)
            .accessibilityIdentifier(AccessibilityID.MyProfile.editBio)

            counter(bio.count, limit: limit)
        }
    }

    private func counter(_ count: Int, limit: Int) -> some View {
        Text(verbatim: "\(count)/\(limit)")
            .appFont(AppFont.caption2)
            .monospacedDigit()
            .foregroundStyle(AppColor.textTertiary)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityLabel(Text(verbatim: "\(limit)자 중 \(count)자 입력"))
    }

    // MARK: - 저장

    private var saveButton: some View {
        PrimaryButton(state.isSaving ? "저장 중..." : "저장") {
            focusedField = nil
            store.send(.saveTapped)
        }
        .disabled(!state.canSave || isLoadingPhoto)
        .accessibilityIdentifier(AccessibilityID.MyProfile.saveProfile)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
        .background(AppColor.background)
    }

    // MARK: - 사진 불러오기

    private func loadPhoto() async {
        guard let selection else { return }
        defer { if !Task.isCancelled { isLoadingPhoto = false } }
        photoError = nil
        do {
            guard let data = try await selection.loadTransferable(type: Data.self),
                let jpeg = await Task.detached(priority: .userInitiated, operation: {
                    ImageDownsampler.downsampledJPEGData(from: data, maxPixelSize: Self.maxPixelSize)
                }).value
            else {
                if !Task.isCancelled { photoError = Self.photoErrorMessage }
                return
            }
            try Task.checkCancellation()
            selectedImage = UIImage(data: jpeg)
            store.send(.photoChanged(.init(data: jpeg, fileName: "profile.jpg", mimeType: "image/jpeg")))
        } catch {
            if !Task.isCancelled { photoError = Self.photoErrorMessage }
        }
    }

    private static let avatarSize: CGFloat = 100
    private static let badgeSize: CGFloat = 30
    /// 업로드할 사진의 긴 변 픽셀 수.
    private static let maxPixelSize: CGFloat = 1024
    private static let photoErrorMessage = "사진을 불러오지 못했어요. 다른 사진을 골라 주세요."
}

#if DEBUG
    #Preview("프로필 편집") {
        var state = MyProfileReducer.State(nickname: "김햄찌", introduction: "매일 아침 루틴을 지키는 햄스터")
        state.edit = .init(nickname: state.nickname, bio: state.introduction)
        return ProfileEditView(store: StoreOf<MyProfileReducer>(state: state, reducer: MyProfileReducer()))
    }
#endif
