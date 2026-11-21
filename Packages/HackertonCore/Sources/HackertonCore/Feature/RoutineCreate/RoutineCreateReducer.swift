import Foundation
import MVICore

/// 루틴 작성 화면.
///
/// 흐름: 선택한 이미지 수만큼 스텝을 작성(이미지·시간·제목·내용)한 뒤 루틴 소개(제목·소개)를 작성하고 완료한다.
/// - 스텝 화면: 첫 스텝이 아니면 이전 버튼을 보여주고, 필수 항목이 올바르면 다음 버튼을 활성화한다.
/// - 마지막 스텝에서 다음을 누르면 루틴 소개 화면으로 간다.
/// - 나가기: 입력한 내용이 있으면 확인 알럿을 띄우고, 없으면 바로 나간다.
///
/// 작성이 끝나면 `State.outcome`에 `RoutineDraft`를 담는다. 화면을 띄운 쪽이 이 값을 받아 처리한다.
public struct RoutineCreateReducer: Reducer {
    /// 한 루틴에 고를 수 있는 이미지(스텝) 최대 개수.
    public static let maxStepCount = 4
    /// 스텝 제목 글자 수.
    public static let stepTitleLength = 5...30
    /// 스텝 내용 최대 글자 수.
    public static let stepContentMaxLength = 100
    /// 루틴 제목 글자 수.
    public static let routineTitleLength = 5...30
    /// 루틴 소개 최대 글자 수.
    public static let routineIntroductionMaxLength = 100

    public init() {}

    public struct Step: Equatable, Identifiable, Sendable {
        public let id: UUID
        public var photo: RoutineDraft.Step.Photo
        public var time: TimeOfDay
        public var title: String
        public var content: String

        public init(
            id: UUID = UUID(),
            image: RoutineImage,
            time: TimeOfDay,
            title: String = "",
            content: String = ""
        ) {
            self.init(id: id, photo: .local(image), time: time, title: title, content: content)
        }

        public init(
            id: UUID = UUID(), photo: RoutineDraft.Step.Photo, time: TimeOfDay, title: String = "", content: String = ""
        ) {
            self.id = id
            self.photo = photo
            self.time = time
            self.title = title
            self.content = content
        }

        public var requiresImageUpload: Bool {
            if case .reference = photo { return true }
            return false
        }

        /// 필수 항목(이미지·시간·제목)이 모두 올바른지 확인한다.
        public var isValid: Bool {
            !requiresImageUpload && RoutineCreateReducer.stepTitleLength.contains(title.trimmingCharacters(in: .whitespacesAndNewlines).count)
                && content.count <= RoutineCreateReducer.stepContentMaxLength
        }

        var hasInput: Bool {
            !title.isEmpty || !content.isEmpty
        }
    }

    public enum Page: Equatable, Sendable {
        /// 스텝 작성. 0부터 시작하는 스텝 순서.
        case step(Int)
        /// 루틴 소개 작성.
        case introduction
    }

    public enum Outcome: Equatable, Sendable {
        case cancelled
        case completed(RoutineDraft)
    }

    public struct State: Equatable {
        public var steps: [Step]
        public var page: Page
        public var routineTitle: String
        public var routineIntroduction: String
        public let introductionLimit: Int
        public var isTimePickerPresented: Bool
        public var isExitAlertPresented: Bool
        /// 화면을 닫아야 할 때 값이 생긴다.
        public var outcome: Outcome?

        public init(
            steps: [Step],
            page: Page? = nil,
            routineTitle: String = "",
            routineIntroduction: String = "",
            isTimePickerPresented: Bool = false,
            isExitAlertPresented: Bool = false,
            outcome: Outcome? = nil,
            introductionLimit: Int = RoutineCreateReducer.routineIntroductionMaxLength
        ) {
            self.steps = steps
            self.page = page ?? (steps.isEmpty ? .introduction : .step(0))
            self.routineTitle = routineTitle
            self.routineIntroduction = routineIntroduction
            self.introductionLimit = introductionLimit
            self.isTimePickerPresented = isTimePickerPresented
            self.isExitAlertPresented = isExitAlertPresented
            self.outcome = outcome
        }

        /// 현재 작성 중인 스텝. 루틴 소개 화면이면 nil.
        public var currentStep: Step? {
            guard case let .step(index) = page, steps.indices.contains(index) else { return nil }
            return steps[index]
        }

        /// 단계 인디케이터에 표시할 현재 단계(1부터). 루틴 소개 화면은 모든 단계를 지난 것으로 본다.
        public var indicatorStep: Int {
            switch page {
            case let .step(index): index + 1
            case .introduction: steps.count + 1
            }
        }

        public var isPreviousVisible: Bool {
            page != .step(0) && !(page == .introduction && steps.isEmpty)
        }

        public var isNextEnabled: Bool {
            currentStep?.isValid ?? false
        }

        public var isCompleteEnabled: Bool {
            RoutineCreateReducer.routineTitleLength.contains(routineTitle.trimmingCharacters(in: .whitespacesAndNewlines).count)
                && routineIntroduction.count <= introductionLimit
                && steps.allSatisfy(\.isValid)
        }

        /// 사용자가 직접 입력한 내용이 있는지. 나가기 확인 알럿을 띄울지 정한다.
        public var hasInput: Bool {
            steps.contains(where: \.hasInput) || !routineTitle.isEmpty || !routineIntroduction.isEmpty
        }
    }

    public enum Action: Equatable {
        case stepImageReplaced(RoutineImage)
        case stepPhotoLoaded(id: UUID, image: RoutineImage, time: TimeOfDay?)
        case timeTapped
        case timeSelected(TimeOfDay)
        case timePickerDismissed
        case stepTitleChanged(String)
        case stepContentChanged(String)
        case routineTitleChanged(String)
        case routineIntroductionChanged(String)
        case previousTapped
        case nextTapped
        case outcomeHandled
        case completeTapped
        case exitTapped
        case requestExitConfirmation
        case draftRestored(steps: [Step], title: String, introduction: String)
        case exitCancelled
        case exitConfirmed
    }

    public func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case let .stepImageReplaced(image):
            updateCurrentStep(&state) { $0.photo = .local(image) }

        case let .stepPhotoLoaded(id, image, time):
            guard let index = state.steps.firstIndex(where: { $0.id == id }) else { break }
            state.steps[index].photo = .local(image)
            if let time { state.steps[index].time = time }

        case .timeTapped:
            if state.currentStep != nil {
                state.isTimePickerPresented = true
            }

        case let .timeSelected(time):
            updateCurrentStep(&state) { $0.time = time }
            state.isTimePickerPresented = false

        case .timePickerDismissed:
            state.isTimePickerPresented = false

        case let .stepTitleChanged(title):
            updateCurrentStep(&state) { $0.title = String(title.prefix(Self.stepTitleLength.upperBound)) }

        case let .stepContentChanged(content):
            updateCurrentStep(&state) { $0.content = String(content.prefix(Self.stepContentMaxLength)) }

        case let .routineTitleChanged(title):
            state.routineTitle = String(title.prefix(Self.routineTitleLength.upperBound))

        case let .routineIntroductionChanged(introduction):
            state.routineIntroduction = String(introduction.prefix(state.introductionLimit))

        case .previousTapped:
            guard state.isPreviousVisible else { break }
            switch state.page {
            case let .step(index):
                state.page = .step(index - 1)
            case .introduction:
                state.page = .step(state.steps.count - 1)
            }

        case .nextTapped:
            guard case let .step(index) = state.page, state.isNextEnabled else { break }
            state.page = index + 1 < state.steps.count ? .step(index + 1) : .introduction

        case .outcomeHandled:
            state.outcome = nil
        case .completeTapped:
            guard state.page == .introduction, state.isCompleteEnabled else { break }
            state.outcome = .completed(makeDraft(from: state))

        case let .draftRestored(steps, title, introduction):
            state.steps = steps
            state.routineTitle = title
            state.routineIntroduction = introduction
            let index = steps.firstIndex(where: { !$0.isValid })
            state.page = index.map(Page.step) ?? .introduction
        case .requestExitConfirmation:
            state.isExitAlertPresented = true
        case .exitTapped:
            if state.hasInput {
                state.isExitAlertPresented = true
            } else {
                state.outcome = .cancelled
            }

        case .exitCancelled:
            state.isExitAlertPresented = false

        case .exitConfirmed:
            state.isExitAlertPresented = false
            state.outcome = .cancelled
        }

        return .none
    }

    private func updateCurrentStep(_ state: inout State, _ update: (inout Step) -> Void) {
        guard case let .step(index) = state.page, state.steps.indices.contains(index) else { return }
        update(&state.steps[index])
    }

    private func makeDraft(from state: State) -> RoutineDraft {
        RoutineDraft(
            title: state.routineTitle,
            introduction: state.routineIntroduction.nilIfBlank,
            steps: state.steps.map { step in
                RoutineDraft.Step(
                    photo: step.photo,
                    time: step.time,
                    title: step.title,
                    content: step.content.nilIfBlank
                )
            }
        )
    }
}

private extension String {
    var nilIfBlank: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}
