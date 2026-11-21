# 개발 지침

- 역할과 책임은 `Docs/IOSDeveloperHandoff.md`를 따른다. UI 개발 2명, 서버 연결·테스트·기타 작업 1명이며 담당자는 미정이다. 디자인시스템 컴포넌트 제작은 공통 책임이다.
- UI 담당은 Figma 구현과 Entity의 화면 연결을 맡고, 서버 연결 담당은 Data layer 전체와 Entity 구성·서버 연동·테스트를 맡는다.
- 화면 상태가 필요한 기능은 기존 MVI 코어를 사용한다. View와 Reducer를 기본으로 두고 State와 Action은 Reducer 내부에 정의한다.
- API 연동은 `Docs/CleanArchitecture.md`를 따른다. 앱의 `Data/<Feature>`에 있는 Endpoint와 Repository 구현체가 요청하고, 패키지의 Mapper가 DTO를 Entity로 변환한 뒤 화면에 전달한다. 서비스별 코드는 실제 기능을 구현할 때 추가한다.
- Figma 구현 요청은 프레임별 Dev Mode 링크의 fileKey와 node-id를 사용한다. 브랜치 링크는 브랜치 키를 사용하며 페이지 링크만 있으면 메타데이터에서 대상 프레임을 찾는다. 대상이 모호하거나 접근이 막히면 프레임 링크 또는 접근 권한을 요청한다.
- Figma 디자인→코드 및 SwiftUI 스킬을 읽고 Figma MCP에서 디자인 컨텍스트와 스크린샷을 확인한다. 컨텍스트 요청에는 clientLanguages=swift, clientFrameworks=swiftui를 지정한다.
- Figma의 변수, 타이포그래피, 간격, 컴포넌트 상태를 기존 AppFont, AppColor, AppSpacing, AppRadius와 공용 SwiftUI 컴포넌트에 매핑한다. 제공된 에셋은 앱 에셋 카탈로그에 등록한다. 실제 화면을 빌드한 뒤 시뮬레이터 스크린샷을 원본 프레임과 비교한다.

## 테스트 규칙

세부 내용은 `Docs/Testing.md`를 따른다.

- Entity, DTO·Mapper, Repository 프로토콜, Reducer는 `Packages/HackertonCore`에 두고 Swift Testing으로 테스트한다. 패키지에서는 Foundation만 사용한다.
- 외부 의존성(Alamofire, Supabase 등)은 프로토콜 뒤에 두고 구현체는 앱 타깃에만 둔다. Mock은 `HackertonMocks`에 둔다.
- Reducer는 의존성을 init으로 받는다. State 전이는 `reduce`를 직접 호출해 검증하고, 경계값은 `@Test(arguments:)`로 한 번에 확인한다.
- Effect는 `ReducerTester`로 send → receive → finish 순서로 검증한다. 호출되면 안 되는 의존성에는 `unimplemented`를 넣는다.
- View는 `init(store:)`로 Store를 받는다. 새 화면이나 공통 컴포넌트를 만들면 State별 스냅샷 테스트를 추가한다.
- 상호작용하는 요소에는 `AccessibilityID` 상수로 `accessibilityIdentifier`를 붙인다. UI 테스트는 `-mock-mode`로 실행한다.
- 버그 수정은 버그를 재현하는 실패 테스트를 먼저 작성하고 실패를 확인한 뒤 고친다.
- 테스트나 스냅샷 기준 이미지를 고쳐서 통과시키지 않는다. 기준 이미지를 다시 찍어야 하면 사용자에게 먼저 묻는다.
- 완료 전 `scripts/test.sh`를 실행한다. 화면을 바꿨으면 `scripts/test.sh app`도 실행한다.
