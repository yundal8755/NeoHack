# 테스트 가이드

MVI의 세 부분을 나눠 검증한다. State 전이와 Effect는 로컬 패키지에서 `swift test`로 몇 초 만에 확인하고, 화면과 핵심 흐름은 시뮬레이터에서 확인한다.

## 계층

| 계층 | 검증 대상 | 도구 | 위치 | 실행 |
| --- | --- | --- | --- | --- |
| 순수 로직 | Mapper, Entity 계산, 입력 검증 | Swift Testing, `@Test(arguments:)` | `Packages/HackertonCore/Tests` | `scripts/test.sh` |
| Reducer State 전이 | `reduce(&state, action)` 후의 State | Swift Testing | `Packages/HackertonCore/Tests` | `scripts/test.sh` |
| Reducer Effect | Effect → Mock Repository → 되돌아오는 Action | Swift Testing + `ReducerTester` | `Packages/HackertonCore/Tests` | `scripts/test.sh` |
| 화면 렌더링 | State별 화면, 공통 컴포넌트 | swift-snapshot-testing | `HackertonBoilerplateSnapshotTests` | `scripts/test.sh app` |
| 핵심 흐름 | 로그인 등 실제 화면 이동 | XCUITest + 목 모드 | `HackertonBoilerplateUITests` | `scripts/test.sh app` |

## 코드 위치

```text
Packages/HackertonCore/
  Sources/
    MVICore/                  Reducer, Effect, Store
    HackertonCore/
      Entity/<Feature>/       앱 모델
      Domain/                 <Feature>Repository 프로토콜, TokenStoring
      DataModel/<Feature>/    DTO, Mapper
      Feature/<Feature>/      <Feature>Reducer (State, Action 내부 정의)
      App/                    AppLaunchConfiguration (목 모드 실행 인자)
      AccessibilityID.swift   View와 UI 테스트가 함께 쓰는 식별자
    HackertonMocks/           Mock Repository, InMemoryTokenStore (테스트와 앱 목 모드에서 사용)
    MVITestSupport/           ReducerTester, unimplemented (테스트 전용)
  Tests/
    MVICoreTests/
    HackertonCoreTests/<Feature>/

HackertonBoilerplate/                  View, Endpoint, Repository 구현체(Alamofire, Supabase 등), AppContainer
HackertonBoilerplateSnapshotTests/     스냅샷 테스트와 __Snapshots__ 기준 이미지
HackertonBoilerplateUITests/
  Screens/                             화면 조작 객체
  Flows/                               흐름 테스트
```

패키지는 Foundation만 사용한다. SwiftUI, UIKit, Alamofire, Supabase를 import하면 `swift test`가 macOS에서 돌지 않으므로 앱 타깃에 둔다.

## Reducer 테스트

의존성은 Reducer의 init으로 받는다. Mock Repository는 클로저로 응답을 바꿔 끼운다.

```swift
// Sources/HackertonCore/Domain/AuthRepository.swift
public protocol AuthRepository: Sendable {
    func login(email: String) async throws -> User
}

// Sources/HackertonMocks/MockAuthRepository.swift
public struct MockAuthRepository: AuthRepository {
    public var login: @Sendable (String) async throws -> User
    public init(login: @escaping @Sendable (String) async throws -> User = { _ in .fixture }) {
        self.login = login
    }
    public func login(email: String) async throws -> User { try await login(email) }
}
```

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
scripts/test.sh            # 패키지 테스트
scripts/test.sh app        # 스냅샷 + UI 테스트
scripts/test.sh all        # 전체
```

`xcbeautify`가 설치되어 있으면 출력을 정리하고, 없으면 `-quiet`로 실행한다.
