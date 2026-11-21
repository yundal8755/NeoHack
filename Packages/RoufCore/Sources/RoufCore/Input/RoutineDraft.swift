import Foundation

/// 루틴 작성 화면에서 고른 이미지. 화면에서 줄여 인코딩한 데이터를 담는다.
/// `id`는 이미지가 바뀔 때마다 새로 만들어 화면이 다시 디코딩할지 판단하는 데 쓴다.
public struct RoutineImage: Equatable, Hashable, Sendable {
    public let id: UUID
    public let data: Data

    public init(id: UUID = UUID(), data: Data) {
        self.id = id
        self.data = data
    }
}

/// 루틴 작성을 마쳤을 때 만들어지는 입력값. 서버 저장 Repository가 생기면 이 값을 넘긴다.
public struct RoutineDraft: Equatable, Sendable {
    public struct Step: Equatable, Sendable {
        public enum Photo: Equatable, Sendable {
            case local(RoutineImage)
            case stored(id: String, url: URL?)
            case reference(URL?)
        }

        public let photo: Photo
        public let time: TimeOfDay
        public let title: String
        /// 선택 항목. 입력하지 않았으면 nil.
        public let content: String?

        public init(image: RoutineImage, time: TimeOfDay, title: String, content: String?) {
            self.init(photo: .local(image), time: time, title: title, content: content)
        }

        public init(photo: Photo, time: TimeOfDay, title: String, content: String?) {
            self.photo = photo
            self.time = time
            self.title = title
            self.content = content
        }
    }

    public let title: String
    /// 선택 항목. 입력하지 않았으면 nil.
    public let introduction: String?
    public let steps: [Step]

    public init(title: String, introduction: String?, steps: [Step]) {
        self.title = title
        self.introduction = introduction
        self.steps = steps
    }
}
