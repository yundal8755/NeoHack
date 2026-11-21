import Foundation
import RoufCore
import MVITestSupport
import Testing

@Suite("RoutineCreateReducer")
struct RoutineCreateReducerTests {
    typealias Feature = RoutineCreateReducer

    let reducer = Feature()

    // MARK: - 시작 상태

    @Test func 첫_스텝에서_시작하고_이전_버튼이_없다() {
        let state = Feature.State(steps: .fixture(count: 3))

        #expect(state.page == .step(0))
        #expect(state.indicatorStep == 1)
        #expect(!state.isPreviousVisible)
        #expect(!state.isNextEnabled)
    }

    // MARK: - 스텝 입력

    @Test(arguments: [
        ("", false),
        ("넷글자임", false),
        ("다섯글자임", true),
        (String(repeating: "가", count: 30), true),
    ])
    func 스텝_제목이_5자에서_30자일_때_다음_버튼이_활성화된다(title: String, enabled: Bool) {
        var state = Feature.State(steps: .fixture(count: 2))

        _ = reducer.reduce(&state, with: .stepTitleChanged(title))

        #expect(state.isNextEnabled == enabled)
    }

    @Test func 스텝_제목은_30자를_넘으면_잘린다() {
        var state = Feature.State(steps: .fixture(count: 1))

        _ = reducer.reduce(&state, with: .stepTitleChanged(String(repeating: "가", count: 31)))

        #expect(state.steps[0].title.count == 30)
    }

    @Test func 스텝_내용은_100자를_넘으면_잘린다() {
        var state = Feature.State(steps: .fixture(count: 1))

        _ = reducer.reduce(&state, with: .stepContentChanged(String(repeating: "가", count: 101)))

        #expect(state.steps[0].content.count == 100)
    }

    @Test func 입력은_현재_스텝에만_반영된다() {
        var state = Feature.State(steps: .fixture(count: 2), page: .step(1))
        let image = RoutineImage(data: Data([9]))

        _ = reducer.reduce(&state, with: .stepTitleChanged("두번째 스텝"))
        _ = reducer.reduce(&state, with: .stepImageReplaced(image))

        #expect(state.steps[0].title.isEmpty)
        #expect(state.steps[1].title == "두번째 스텝")
        #expect(state.steps[1].photo == .local(image))
    }

    @Test func 사진을_읽는_동안_스텝이_바뀌어도_원래_스텝에_반영된다() {
        var state = Feature.State(steps: .fixture(count: 2), page: .step(1))
        let firstID = state.steps[0].id
        let secondPhoto = state.steps[1].photo
        let photo = RoutineImage(data: Data([42]))
        let time = TimeOfDay(hour: 8, minute: 30)

        _ = reducer.reduce(&state, with: .stepPhotoLoaded(id: firstID, image: photo, time: time))

        #expect(state.steps[0].photo == .local(photo))
        #expect(state.steps[0].time == time)
        #expect(state.steps[1].photo == secondPhoto)
        #expect(state.page == .step(1))
    }

    // MARK: - 시간 선택

    @Test func 시간을_누르면_시트를_띄우고_선택하면_현재_스텝에_반영하고_닫는다() {
        var state = Feature.State(steps: .fixture(count: 1))
        let time = TimeOfDay(hour: 23, minute: 30)

        _ = reducer.reduce(&state, with: .timeTapped)
        #expect(state.isTimePickerPresented)

        _ = reducer.reduce(&state, with: .timeSelected(time))
        #expect(!state.isTimePickerPresented)
        #expect(state.steps[0].time == time)
    }

    @Test func 시트를_닫으면_시간은_그대로다() {
        var state = Feature.State(steps: .fixture(count: 1), isTimePickerPresented: true)
        let before = state.steps[0].time

        _ = reducer.reduce(&state, with: .timePickerDismissed)

        #expect(!state.isTimePickerPresented)
        #expect(state.steps[0].time == before)
    }

    // MARK: - 페이지 이동

    @Test func 필수_항목이_없으면_다음으로_넘어가지_않는다() {
        var state = Feature.State(steps: .fixture(count: 2))

        _ = reducer.reduce(&state, with: .nextTapped)

        #expect(state.page == .step(0))
    }

    @Test func 다음과_이전으로_스텝과_루틴_소개_사이를_이동한다() {
        var state = Feature.State(steps: .fixture(count: 2, title: "다섯글자임"))

        _ = reducer.reduce(&state, with: .nextTapped)
        #expect(state.page == .step(1))
        #expect(state.isPreviousVisible)

        _ = reducer.reduce(&state, with: .nextTapped)
        #expect(state.page == .introduction)
        #expect(state.indicatorStep == 3)

        _ = reducer.reduce(&state, with: .previousTapped)
        #expect(state.page == .step(1))

        _ = reducer.reduce(&state, with: .previousTapped)
        #expect(state.page == .step(0))

        _ = reducer.reduce(&state, with: .previousTapped)
        #expect(state.page == .step(0))
    }

    // MARK: - 완료

    @Test(arguments: [
        ("", "", false),
        ("넷글자임", "", false),
        ("다섯글자임", "", true),
        ("다섯글자임", "소개", true),
    ])
    func 루틴_제목이_5자에서_30자일_때_완료_버튼이_활성화된다(title: String, introduction: String, enabled: Bool) {
        var state = Feature.State(steps: .fixture(count: 1, title: "다섯글자임"), page: .introduction)

        _ = reducer.reduce(&state, with: .routineTitleChanged(title))
        _ = reducer.reduce(&state, with: .routineIntroductionChanged(introduction))

        #expect(state.isCompleteEnabled == enabled)
    }

    @Test func 루틴_소개는_100자를_넘으면_잘린다() {
        var state = Feature.State(steps: .fixture(count: 1), page: .introduction)

        _ = reducer.reduce(&state, with: .routineIntroductionChanged(String(repeating: "가", count: 101)))

        #expect(state.routineIntroduction.count == 100)
    }

    @Test func 완료하면_입력한_내용으로_초안을_만든다() async {
        let steps: [Feature.Step] = .fixture(count: 2, title: "다섯글자임")
        let tester = await ReducerTester(
            reducer,
            state: Feature.State(steps: steps, page: .introduction, routineTitle: "김햄찌의 하루", routineIntroduction: "  ")
        )

        await tester.send(.completeTapped) {
            $0.outcome = .completed(
                RoutineDraft(
                    title: "김햄찌의 하루",
                    introduction: nil,
                    steps: steps.map {
                        RoutineDraft.Step(photo: $0.photo, time: $0.time, title: "다섯글자임", content: nil)
                    }
                )
            )
        }
        await tester.finish()
    }

    @Test func 완료_조건을_채우지_않으면_완료되지_않는다() {
        var state = Feature.State(steps: .fixture(count: 1, title: "다섯글자임"), page: .introduction)

        _ = reducer.reduce(&state, with: .completeTapped)

        #expect(state.outcome == nil)
    }

    // MARK: - 나가기

    @Test func 입력한_내용이_없으면_바로_나간다() {
        var state = Feature.State(steps: .fixture(count: 2))

        _ = reducer.reduce(&state, with: .exitTapped)

        #expect(!state.isExitAlertPresented)
        #expect(state.outcome == .cancelled)
    }

    @Test func 입력한_내용이_있으면_확인_알럿을_띄우고_취소하면_남는다() {
        var state = Feature.State(steps: .fixture(count: 2, title: "제목"))

        _ = reducer.reduce(&state, with: .exitTapped)
        #expect(state.isExitAlertPresented)
        #expect(state.outcome == nil)

        _ = reducer.reduce(&state, with: .exitCancelled)
        #expect(!state.isExitAlertPresented)
        #expect(state.outcome == nil)
    }

    @Test func 확인_알럿에서_확인하면_나간다() {
        var state = Feature.State(steps: .fixture(count: 2, title: "제목"), isExitAlertPresented: true)

        _ = reducer.reduce(&state, with: .exitConfirmed)

        #expect(!state.isExitAlertPresented)
        #expect(state.outcome == .cancelled)
    }
}

extension [RoutineCreateReducer.Step] {
    static func fixture(count: Int, title: String = "") -> Self {
        (0..<count).map { index in
            RoutineCreateReducer.Step(
                image: RoutineImage(data: Data([UInt8(index)])),
                time: TimeOfDay(hour: 10, minute: 30),
                title: title
            )
        }
    }
}
