import Foundation
import MVICore

nonisolated struct MyProfileReducer: Reducer {
    let users: (any UserRepository)?
    let images: (any ImageRepository)?

    init(users: (any UserRepository)? = nil, images: (any ImageRepository)? = nil) {
        self.users = users
        self.images = images
    }

    struct Edit: Equatable {
        var nickname: String
        var bio: String
        var photo: ImageUploadInput?
        var uploadedImageID: String?
    }

    enum Tab: Equatable {
        case mine
        case participating
    }

    struct State: Equatable {
        var nickname: String
        var introduction: String
        var myRoutines: [HomeReducer.Routine]
        /// 최신 참여순으로 전달받은 목록. 루틴 생성일과 참여일은 다르므로 다시 정렬하지 않는다.
        var participatingRoutines: [HomeReducer.Routine]
        var selectedTab: Tab = .mine
        var notice: String?
        var updatedProfile: UserEntity?
        var edit: Edit?
        var isSaving = false
        var editError: String?

        var hasEdits: Bool {
            guard let edit else { return false }
            return edit.nickname.trimmingCharacters(in: .whitespacesAndNewlines) != nickname
                || edit.bio != introduction || edit.photo != nil
        }

        init(nickname: String, introduction: String, myRoutines: [HomeReducer.Routine] = [], participatingRoutines: [HomeReducer.Routine] = []) {
            self.nickname = nickname
            self.introduction = introduction
            self.myRoutines = myRoutines
            self.participatingRoutines = participatingRoutines
        }

        var visibleRoutines: [HomeReducer.Routine] {
            switch selectedTab {
            case .mine:
                myRoutines.sorted {
                    let left = $0.createdAt ?? .distantPast
                    let right = $1.createdAt ?? .distantPast
                    if left != right { return left > right }
                    return $0.id < $1.id
                }
            case .participating: participatingRoutines
            }
        }
    }

    enum Action {
        case tabSelected(Tab)
        case editTapped
        case nicknameChanged(String)
        case bioChanged(String)
        case photoChanged(ImageUploadInput)
        case closeEditor
        case saveTapped
        case photoUploaded(String)
        case profileSaved(UserEntity)
        case saveFailed(String)
        case noticeDismissed
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case let .tabSelected(tab): state.selectedTab = tab
        case .editTapped:
            guard users != nil else {
                state.notice = "프로필 편집은 연결된 계정에서 사용할 수 있어요."
                return .none
            }
            state.edit = Edit(nickname: state.nickname, bio: state.introduction)
            state.editError = nil
        case let .nicknameChanged(value):
            guard !state.isSaving else { return .none }
            state.edit?.nickname = value
        case let .bioChanged(value):
            guard !state.isSaving else { return .none }
            state.edit?.bio = value
        case let .photoChanged(input):
            guard !state.isSaving else { return .none }
            state.edit?.photo = input
            state.edit?.uploadedImageID = nil
        case .closeEditor:
            guard !state.isSaving else { return .none }
            state.edit = nil
        case .saveTapped:
            return save(&state)
        case let .photoUploaded(id):
            state.edit?.uploadedImageID = id
        case let .profileSaved(profile):
            state.isSaving = false
            state.nickname = profile.nickname
            state.introduction = profile.bio ?? ""
            state.updatedProfile = profile
            state.edit = nil
        case let .saveFailed(message):
            state.isSaving = false
            state.editError = message
        case .noticeDismissed: state.notice = nil
        }
        return .none
    }

    private func save(_ state: inout State) -> Effect<Action> {
        guard let users, let images, let edit = state.edit, state.hasEdits, !state.isSaving else { return .none }
        let nickname = edit.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let bio: UserProfileUpdate.BioChange? = if edit.bio == state.introduction {
            nil
        } else if edit.bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            .clear
        } else {
            .set(edit.bio)
        }
        let update = UserProfileUpdate(nickname: nickname == state.nickname ? nil : nickname, bio: bio,
                                       profileImageID: edit.uploadedImageID)
        do { try update.validate() } catch {
            state.editError = error.localizedDescription
            return .none
        }
        state.isSaving = true
        state.editError = nil
        return .run { send in
            do {
                var pending = update
                if let photo = edit.photo, pending.profileImageID == nil {
                    let uploaded = try await images.uploadProfile(input: photo)
                    pending.profileImageID = uploaded.id
                    await send(.photoUploaded(uploaded.id))
                }
                try Task.checkCancellation()
                await send(.profileSaved(try await users.updateProfile(pending)))
            } catch {
                await send(.saveFailed(error.localizedDescription))
            }
        }.cancelTask(id: "saveProfile")
    }
}
