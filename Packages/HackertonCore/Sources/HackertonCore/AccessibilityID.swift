import Foundation

/// View의 `accessibilityIdentifier`와 XCUITest가 함께 쓰는 식별자.
/// 화면을 추가하면 같은 이름의 하위 enum을 만들고 `<화면>.<요소>` 형식으로 값을 정한다.
/// 공통 컴포넌트는 `<컴포넌트>.<요소>` 형식을 쓴다.
public enum AccessibilityID {
    public enum Home {
        public static let sortButton = "home.sortButton"
        public static let createButton = "home.createButton"
        public static func routine(_ id: Int) -> String { "home.routine.\(id)" }
    }
    public enum RoutineDetail {
        public static let screen = "routineDetail.screen"
        public static let likeButton = "routineDetail.likeButton"
        public static let commentsButton = "routineDetail.commentsButton"
        public static let allCommentsButton = "routineDetail.allCommentsButton"
        public static let participateButton = "routineDetail.participateButton"
        public static let commentField = "routineDetail.commentField"
        public static let submitCommentButton = "routineDetail.submitCommentButton"
    }
    public enum Root {
        public static let homeScreen = "root.homeScreen"
    }

    public enum RoutineCreate {
        /// 사진을 고르기 전 루틴 만들기 진입 화면.
        public static let entry = "routineCreate.entry"
        public static let screen = "routineCreate.screen"
        public static let stepImage = "routineCreate.stepImage"
        public static let timeChip = "routineCreate.timeChip"
        public static let stepTitleField = "routineCreate.stepTitleField"
        public static let stepContentField = "routineCreate.stepContentField"
        public static let routineTitleField = "routineCreate.routineTitleField"
        public static let routineIntroductionField = "routineCreate.routineIntroductionField"
        public static let previousButton = "routineCreate.previousButton"
        public static let nextButton = "routineCreate.nextButton"
        public static let completeButton = "routineCreate.completeButton"
        public static let dismissKeyboardButton = "routineCreate.dismissKeyboardButton"
    }

    public enum TopBar {
        public static let leadingButton = "topBar.leadingButton"
        public static let trailingButton = "topBar.trailingButton"
    }

    public enum TimePicker {
        public static let periodWheel = "timePicker.periodWheel"
        public static let hourWheel = "timePicker.hourWheel"
        public static let minuteWheel = "timePicker.minuteWheel"
        public static let cancelButton = "timePicker.cancelButton"
        public static let confirmButton = "timePicker.confirmButton"
    }
}
