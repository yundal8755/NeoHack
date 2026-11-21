# 테스트 가이드

MVI의 세 부분을 나눠 검증한다. 공통 MVI와 폼 검증은 로컬 패키지에서 확인하고, 서버 Repository를 사용하는 화면과 Reducer는 시뮬레이터에서 검증한다.

## 계층

| 계층 | 검증 대상 | 도구 | 위치 | 실행 |
| --- | --- | --- | --- | --- |
| 새 Data·Domain | DTO, Mapper, Entity, Endpoint, Repository·multipart·오류 | Swift Testing + URLProtocol | `RoufSnapshotTests/DataDomain` | `scripts/test.sh app -only-testing:RoufSnapshotTests/DataDomainTests` |
| Reducer State 전이 | `reduce(&state, action)` 후의 State | Swift Testing | `Packages/RoufCore/Tests` | `scripts/test.sh` |
| Reducer Effect | Effect → Mock Repository → 되돌아오는 Action | Swift Testing + `ReducerTester` | `Packages/RoufCore/Tests` | `scripts/test.sh` |
| 화면 렌더링 | State별 화면, 공통 컴포넌트 | swift-snapshot-testing | `RoufSnapshotTests` | `scripts/test.sh app` |
| 핵심 흐름 | 로그인 등 실제 화면 이동 | XCUITest + 목 모드 | `RoufUITests` | `scripts/test.sh app` |

## 코드 위치

```text
Packages/RoufCore/
  Sources/
    MVICore/                  Reducer, Effect, Store
    RoufCore/
      Domain/                 기존 TokenStoring
      DataModel/Example/      기존 Example DTO (새 서비스 범위 제외)
      Feature/<Feature>/      <Feature>Reducer (State, Action 내부 정의)
      App/                    AppLaunchConfiguration (목 모드 실행 인자)
      AccessibilityID.swift   View와 UI 테스트가 함께 쓰는 식별자
    RoufMocks/           Mock Repository, InMemoryTokenStore (테스트와 앱 목 모드에서 사용)
    MVITestSupport/           ReducerTester, unimplemented (테스트 전용)
  Tests/
    MVICoreTests/
    RoufCoreTests/<Feature>/

Rouf/
  Domain/<DomainName>/                Entity, Input, Repository protocol
  Data/<DomainName>/                  DTO/Request, DTO/Response, Mapper, Endpoint, RepositoryImpl
  App/, Core/, Presentation/         기존 앱 기반·화면
RoufSnapshotTests/     스냅샷 테스트와 __Snapshots__ 기준 이미지
  DataDomain/                          앱 Data·Domain의 Swift Testing (스냅샷 아님)
RoufUITests/
  Screens/                             화면 조작 객체
  Flows/                               흐름 테스트
```

패키지는 Foundation만 사용한다. SwiftUI, UIKit, Alamofire, Supabase를 import하면 `swift test`가 macOS에서 돌지 않으므로 앱 타깃에 둔다.

## Reducer 테스트

의존성은 Reducer의 init으로 받는다. 기존 패키지의 테스트 대역은 RoufMocks를 사용한다. 홈·상세 Reducer는 앱 타깃에서 Domain Repository를 주입받으며, 앱 테스트 번들에서 요청과 State 변경을 검증한다.

State 전이는 `reduce`를 직접 호출하고, 경계값은 파라미터 테스트로 한 번에 확인한다. 네트워크가 끼면 안 되는 테스트에는 `unimplemented`를 넣는다. 호출되면 테스트가 실패한다.

```swift
@Test(arguments: [("", false), ("a@b", false), ("a@b.com", true)])
func 이메일_형식에_따라_로그인_버튼이_활성화된다(email: String, enabled: Bool) {
    var state = LoginReducer.State()
    let reducer = LoginReducer(repository: MockAuthRepository(login: unimplemented("login")))

    _ = reducer.reduce(&state, with: .emailChanged(email))

    #expect(state.isLoginEnabled == enabled)
}
```

Effect는 `ReducerTester`로 `send` → `receive` → `finish` 순서로 검증한다.

```swift
@Test @MainActor
func 로그인_성공시_유저가_저장된다() async {
    let tester = ReducerTester(
        LoginReducer(repository: MockAuthRepository(login: { _ in .fixture })),
        state: .init(email: "a@b.com")
    )

    await tester.send(.loginTapped) { $0.isLoading = true }
    await tester.receive({ if case .loginResponse(.success) = $0 { true } else { false } }) {
        $0.isLoading = false
        $0.user = .fixture
    }
    tester.finish()
}
```

## 스냅샷 테스트

- View는 `init(store:)`로 Store를 받는다. 테스트에서 원하는 State를 넣은 Store를 만들어 State별로 한 장씩 찍는다.
- 컴포넌트는 `.component`, 화면은 `.screen` 전략을 쓴다(`SnapshotSupport.swift`).
- 기준 이미지가 없으면 첫 실행에서 기록하고 실패한다. 이미지를 확인한 뒤 다시 실행하면 통과한다.
- 기준 이미지는 iPhone 17 / iOS 26.2에서 기록했다. 기기나 OS가 다르면 이미지가 달라진다.
- 의도한 디자인 변경으로 기준 이미지를 다시 찍을 때는 해당 png를 지우고 다시 실행한다. 이유를 PR에 적는다.

## UI 테스트

- 앱은 `-mock-mode` 실행 인자가 있으면 AppContainer에서 Mock 구현체를 주입한다. UI 테스트는 항상 목 모드로 실행한다.
- 실행 인자는 `AppLaunchConfiguration.launchArguments(for: .mock(.default))`로 만든다. 실패 흐름은 `MockScenario`를 추가해 고른다.
- 상호작용하는 요소에는 `AccessibilityID` 상수로 `accessibilityIdentifier`를 붙이고, 테스트도 같은 상수로 찾는다.
- XCUITest는 Swift Testing을 지원하지 않아 XCTest로 작성한다.

## 실행

```bash
scripts/test.sh core --scratch-path /tmp/Rouf-core-tests  # 패키지 테스트; 추적 중인 기존 .build 보호
scripts/test.sh app -only-testing:RoufSnapshotTests/DataDomainTests  # 새 계층만
scripts/test.sh app        # 스냅샷 + UI 테스트
scripts/test.sh all        # 전체
```

`xcbeautify`가 설치되어 있으면 출력을 정리하고, 없으면 설치 안내를 한 줄 띄운 뒤 빌드 오류, 실패한 테스트와 이유, 최종 결과만 걸러서 보여준다. 설치는 선택이며 권장한다(`brew install xcbeautify`).

## push 전 자동 테스트

`.githooks/pre-push`는 `dev`나 `main`으로 push할 때 `scripts/test.sh`를 먼저 실행하고, 실패하면 push를 막는다. 다른 브랜치로의 push는 검사하지 않는다. 클론마다 한 번 활성화한다.

```bash
git config core.hooksPath .githooks
```

- 기본은 패키지 로직 테스트(`core`)만 실행한다. 화면을 바꿨으면 `PRE_PUSH_TESTS=all git push origin <브랜치>:dev`로 스냅샷·UI 테스트까지 실행한다.
- 테스트는 현재 작업 폴더 기준으로 돈다. 커밋하지 않은 변경이 있으면 경고를 띄운다.
- `git push --no-verify`로 건너뛸 수 있지만 쓰지 않는다.

## 커밋 전 스킴 검사

`.githooks/pre-commit`은 공유 스킴(`Rouf.xcscheme`)이 커밋에 포함될 때만 동작한다. 스테이징된 스킴에 `RoufSnapshotTests`와 `RoufUITests` 테스트 대상이 없거나 스킴을 삭제하면 커밋을 막는다. Xcode 표준 형식이 아니면 경고만 띄운다. 활성화는 pre-push와 같다(`git config core.hooksPath .githooks`).

- 열린 Xcode가 이전 스킴으로 파일을 덮어써 테스트 대상이 사라지는 일을 막기 위한 검사다. 막히면 Xcode를 종료하고 `git restore --staged --worktree <스킴 경로>`로 되돌린다.
- 테스트 타깃을 추가·삭제하면 `.githooks/pre-commit`의 `REQUIRED_TESTABLES`도 함께 고친다.

DataDomain 테스트는 URLProtocol과 주입한 Alamofire Session을 사용하여 실서버에 접속하지 않는다. Snapshot·UI 테스트와 별도로 실행하며 기준 이미지를 기록하지 않는다. 기본 iOS 26.2 런타임이 없으면 TEST_DESTINATION에 설치된 시뮬레이터를 지정한다.


실제 서버로 확인할 때는 시뮬레이터에서 사용 가능한 테스트 계정을 선택한다. 앱을 종료해 갱신이 중단되면 사용권은 서버에서 만료된다.
