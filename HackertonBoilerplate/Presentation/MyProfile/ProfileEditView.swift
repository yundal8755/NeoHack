import HackertonCore
import MVICore
import PhotosUI
import SwiftUI

struct ProfileEditView: View {
    @ObservedObject var store: StoreOf<MyProfileReducer>
    let imageURL: URL?
    @State private var selection: PhotosPickerItem?
    @State private var isLoadingPhoto = false
    @State private var photoError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        if let data = store.state.edit?.photo?.data, let image = UIImage(data: data) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                                .accessibilityHidden(true)
                        } else {
                            ProfileAvatar(url: imageURL, size: 56)
                        }
                        PhotosPicker(selection: $selection, matching: .images) {
                            Text("프로필 사진 변경")
                        }
                        .accessibilityIdentifier(AccessibilityID.MyProfile.editPhoto)
                        if isLoadingPhoto { ProgressView() }
                    }
                    if let photoError { Text(photoError).foregroundStyle(AppColor.error) }
                }
                Section("닉네임") {
                    TextField("2~10자", text: Binding(
                        get: { store.state.edit?.nickname ?? "" },
                        set: { store.send(.nicknameChanged($0)) }))
                    .accessibilityIdentifier(AccessibilityID.MyProfile.editNickname)
                }
                Section("한 줄 소개") {
                    TextField("최대 50자", text: Binding(
                        get: { store.state.edit?.bio ?? "" },
                        set: { store.send(.bioChanged($0)) }))
                    .accessibilityIdentifier(AccessibilityID.MyProfile.editBio)
                }
                if let message = store.state.editError {
                    Section { Text(message).foregroundStyle(AppColor.error) }
                }
            }
            .disabled(store.state.isSaving)
            .navigationTitle("프로필 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { store.send(.closeEditor) }
                        .disabled(store.state.isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if store.state.isSaving {
                        ProgressView().accessibilityLabel("프로필 저장 중")
                    } else {
                        Button("저장") { store.send(.saveTapped) }
                            .disabled(!store.state.hasEdits || isLoadingPhoto)
                            .accessibilityIdentifier(AccessibilityID.MyProfile.saveProfile)
                    }
                }
            }
        }
        .interactiveDismissDisabled(store.state.isSaving)
        .onChange(of: selection) { _, item in isLoadingPhoto = item != nil }
        .task(id: selection) {
            guard let selection else { return }
            defer { if !Task.isCancelled { isLoadingPhoto = false } }
            photoError = nil
            do {
                guard let data = try await selection.loadTransferable(type: Data.self),
                      let jpeg = await Task.detached(priority: .userInitiated, operation: {
                          ImageDownsampler.downsampledJPEGData(from: data, maxPixelSize: 1024)
                      }).value else {
                    if !Task.isCancelled { photoError = "사진을 불러오지 못했어요. 다른 사진을 골라 주세요." }
                    return
                }
                try Task.checkCancellation()
                store.send(.photoChanged(.init(data: jpeg, fileName: "profile.jpg", mimeType: "image/jpeg")))
            } catch {
                if !Task.isCancelled { photoError = "사진을 불러오지 못했어요. 다른 사진을 골라 주세요." }
            }
        }
    }
}
