import Foundation
import HackertonCore

/// 현재 UI 확인용 데이터. DTO·서버 계약을 가정하지 않으며 호출마다 독립된 State를 반환한다.
public enum MockRoutineData {
    public static var home: HomeReducer.State {
        let titles = ["김햄찌의 하루", "느긋한 주말 아침", "퇴근 후 작은 산책", "오늘은 집밥", "책과 함께하는 밤", "출근길 새로운 발견", "방 정리하는 오후", "친구와 동네 한 바퀴", "하루 한 곡 집중하기", "나만의 카페 시간", "잠들기 전 스트레칭", "일요일 저녁 기록"]
        let names = ["김햄찌", "나", "산책러", "집밥요정", "책갈피", "발견왕"]
        let routines: [HomeReducer.Routine] = titles.indices.map { index in
            var state = detail
            state.title = titles[index]
            state.comments = Array(state.comments.prefix(index % 13))
            state.commentCount = state.comments.count
            state.isOwner = index == 1
            state.isLiked = index % 3 == 1
            switch index % 3 {
            case 1: state.participation = .completed
            case 2: state.participation = .joined
            default: state.participation = .notJoined
            }
            if state.isOwner { state.participation = .notJoined }
            state.likeCount = 10 + (index * 7) % 31
            state.participatingCount = index % 5 + (state.participation == .joined ? 1 : 0)
            state.completedCount = index * 2 + (state.participation == .completed ? 1 : 0)
            return HomeReducer.Routine(
                id: index,
                nickname: names[index % names.count],
                introduction: index == 0 ? "제 찐 일상인데요... 딱히 재밌는 건 없네요" : "익숙한 하루를 조금 다르게 보내는 나만의 루틴이에요.",
                createdAt: Date(timeIntervalSince1970: 1_795_262_400 - Double(index) * 3600),
                detail: state
            )
        }
        return HomeReducer.State(routines: routines)
    }

    public static var profile: MyProfileReducer.State {
        let rows = home.routines
        let mine = rows.prefix(3).map { routine -> HomeReducer.Routine in
            var detail = routine.detail
            detail.isOwner = true
            detail.participation = .notJoined
            return HomeReducer.Routine(id: routine.id, nickname: "김햄찌", introduction: routine.introduction, createdAt: routine.createdAt, detail: detail)
        }
        let joined = rows.dropFirst(3).prefix(5).map { routine -> HomeReducer.Routine in
            var detail = routine.detail
            detail.isOwner = false
            if detail.participation == .notJoined { detail.participation = .joined }
            return HomeReducer.Routine(id: routine.id, nickname: routine.nickname, introduction: routine.introduction, createdAt: routine.createdAt, detail: detail)
        }
        return MyProfileReducer.State(nickname: "김햄찌", introduction: "김햄찌 너무 귀여워요. 최고최고", myRoutines: mine, participatingRoutines: joined)
    }

    public static var emptyHome: HomeReducer.State { .init() }

    public static var detail: RoutineDetailReducer.State {
        let steps: [RoutineDetailReducer.Step] = [
            .init(id: 1, time: "10:30", title: "아침에 지하철 타러가요", content: "아침에 역시나 사람이 많아요. 매일 타는 지하철에서 오늘은 창밖 풍경을 천천히 바라봐요."),
            .init(id: 2, time: "12:30", title: "점심에는 새로운 메뉴", content: "늘 먹던 메뉴 대신 오늘 처음 눈에 들어오는 음식을 골라봐요."),
            .init(id: 3, time: "18:00", title: "퇴근길 한 정거장 걷기", content: "조금 일찍 내려서 동네 골목을 걸어요. 처음 보는 가게를 발견하면 잠깐 멈춰봐요."),
            .init(id: 4, time: "22:00", title: "오늘의 작은 발견 기록", content: "오늘 달라진 순간을 한 줄 남기고 하루를 마무리해요.")
        ]
        return .init(title: "김햄찌의 하루", steps: steps, comments: comments, likeCount: 10, commentCount: comments.count, participatingCount: 3, completedCount: 10)
    }

    public static var ownRoutine: RoutineDetailReducer.State {
        var state = detail
        state.isOwner = true
        state.title = "내가 만든 작은 일상"
        return state
    }

    public static var participatingRoutine: RoutineDetailReducer.State {
        var state = detail
        state.participation = .joined
        return state
    }

    public static var completedRoutine: RoutineDetailReducer.State {
        var state = detail
        state.participation = .completed
        return state
    }

    public static var noComments: RoutineDetailReducer.State {
        var state = detail
        state.comments = []
        state.commentCount = 0
        return state
    }

    public static var commentDraft: RoutineDetailReducer.State {
        var state = detail
        state.commentDraft = "저도 오늘부터 함께 해볼게요!"
        return state
    }

    public static var editingComment: RoutineDetailReducer.State {
        var state = detail
        if let comment = state.comments.first(where: \.isMine) {
            state.editingCommentID = comment.id
            state.commentDraft = comment.content
        }
        return state
    }

    public static var longContent: RoutineDetailReducer.State {
        var state = detail
        state.title = "익숙한 하루를 조금씩 다르게 살아보는 나만의 특별한 루틴"
        state.steps = [
            .init(id: 1, time: "23:55", title: "긴 제목이 들어왔을 때 화면이 자연스럽게 줄바꿈되는지 확인하는 단계", content: String(repeating: "바쁜 하루에도 잠깐 멈추고 주변을 둘러봐요. ", count: 5)),
            .init(id: 2, time: "", title: "선택 항목이 없는 단계", content: "")
        ]
        return state
    }

    /// 실패 경로만 확인하는 URL. 기본 프리뷰는 네트워크를 사용하지 않는다.
    public static var imageFailure: RoutineDetailReducer.State {
        var state = detail
        state.steps = [.init(id: 1, time: "10:30", title: "이미지를 불러올 수 없는 경우", content: "이미지 요청 실패 시 대체 화면을 확인해요.", imageURL: URL(string: "https://example.invalid/routine.jpg"))]
        return state
    }

    private static var comments: [RoutineDetailReducer.Comment] {
        let names = ["산책러", "책갈피", "나", "느림보"]
        let contents = ["익숙한 하루를 다르게 보는 방법이 좋네요!", "오늘 퇴근길에 따라 해볼게요.", "직접 해보니 작은 변화가 기분 전환이 되네요.", "사진 없이 글만 읽어도 하루가 상상돼요."]
        return (0..<12).map { index in
            var comment = RoutineDetailReducer.Comment(
                id: index + 1,
                nickname: names[index % names.count],
                dateText: String(format: "26. 11. 21. %02d:%02d", 10 + index / 2, index % 2 * 30),
                content: index == 11 ? String(repeating: "가", count: 50) : contents[index % contents.count]
            )
            comment.isMine = index % names.count == 2
            return comment
        }
    }
}
