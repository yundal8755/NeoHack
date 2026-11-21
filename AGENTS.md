# 개발 지침

- 역할과 책임은 `Docs/IOSDeveloperHandoff.md`를 따른다. UI 개발 2명, 서버 연결·테스트·기타 작업 1명이며 담당자는 미정이다. 디자인시스템 컴포넌트 제작은 공통 책임이다.
- UI 담당은 Figma 구현과 Entity의 화면 연결을 맡고, 서버 연결 담당은 Data layer 전체와 Entity 구성·서버 연동·테스트를 맡는다.
- `dev` 반영은 PR 작성이나 팀원 리뷰·승인을 필수 단계로 요구하지 않는다. 개인 작업 브랜치의 변경을 로컬에서 `dev`에 병합한 뒤 원격 `dev`로 직접 push하는 방식을 사용한다.
- 화면 상태가 필요한 기능은 기존 MVI 코어를 사용한다. View와 Reducer를 기본으로 두고 State와 Action은 Reducer 내부에 정의한다.
- API 연동은 `Docs/CleanArchitecture.md`를 따른다. 앱의 `Data/<Feature>`에 있는 Endpoint와 Repository 구현체가 요청하고, 패키지의 Mapper가 DTO를 Entity로 변환한 뒤 화면에 전달한다. 서비스별 코드는 실제 기능을 구현할 때 추가한다.
- UI 계층(View·Reducer)은 DTO를 직접 생성·참조·인코딩·디코딩하지 않는다. State와 Action에도 DTO를 보관하지 않는다. View는 State와 Action을 사용하고, Reducer는 init으로 주입받은 Repository 프로토콜과 Entity를 사용한다.
- Repository 프로토콜의 입력·반환 타입에 DTO를 노출하지 않는다. 입력은 기본 타입이나 앱 입력 모델로 받고, Repository 구현체가 요청 DTO를 생성한다. 응답 DTO는 구현체에서 Mapper를 거쳐 Entity로 변환해 반환한다.
- 현재 단계는 DTO만 준비한다. Entity는 아직 생성하지 않으며, UI 연결을 위해 DTO를 Entity 대신 사용하는 우회 구현도 하지 않는다.
- Figma 구현 요청은 프레임별 Dev Mode 링크의 fileKey와 node-id를 사용한다. 브랜치 링크는 브랜치 키를 사용하며 페이지 링크만 있으면 메타데이터에서 대상 프레임을 찾는다. 대상이 모호하거나 접근이 막히면 프레임 링크 또는 접근 권한을 요청한다.
- Figma 디자인→코드 및 SwiftUI 스킬을 읽고 Figma MCP에서 디자인 컨텍스트와 스크린샷을 확인한다. 컨텍스트 요청에는 clientLanguages=swift, clientFrameworks=swiftui를 지정한다.
- Figma의 변수, 타이포그래피, 간격, 컴포넌트 상태를 기존 AppFont, AppColor, AppSpacing, AppRadius와 공용 SwiftUI 컴포넌트에 매핑한다. 제공된 에셋은 앱 에셋 카탈로그에 등록한다. 실제 화면을 빌드한 뒤 시뮬레이터 스크린샷을 원본 프레임과 비교한다.

## Xcode 프로젝트 파일

- `.xcodeproj`(`project.pbxproj`, `.xcscheme`)를 Xcode 밖에서 수정하거나 pull·merge·reset으로 바꾸기 전에 Xcode를 종료한다. 열린 Xcode는 메모리의 이전 내용으로 파일을 다시 저장해 변경을 덮어쓴다.
- 스킴은 Xcode의 Edit Scheme에서 수정하고 Xcode가 저장한 형식 그대로 커밋한다. 스킴 XML을 직접 작성하거나 한 줄 속성 형식으로 고치지 않는다.
- 스킴이 변경 목록에 있으면 커밋 전에 `git diff`로 의도한 변경인지 확인한다. 테스트 대상(`HackertonBoilerplateSnapshotTests`, `HackertonBoilerplateUITests`)이 빠진 스킴은 `.githooks/pre-commit`이 커밋을 막는다.

## 외부 라이브러리와 공통 코드

- 새 기능 구현 전 `Core`와 `App/Constant`의 기존 공통 코드를 먼저 확인하고 우선 재사용한다. 같은 역할의 컴포넌트나 유틸리티를 중복 구현하지 않는다.
- **Alamofire**: 서버 API 요청과 응답 처리에 사용한다. 기능별 Endpoint는 기존 `TargetType`을 구현하고, Repository는 AppContainer에서 주입받은 `NetworkManager`를 사용한다. 인증 헤더, 디코딩, 네트워크 오류 처리는 기존 `AuthInterceptor`, `CodableManager`, `NetworkError`를 재사용한다.
- **Kingfisher**: 원격 이미지 기능에 반드시 사용하고, 기존 `NetworkImageView`를 우선 재사용한다. 표시 크기에 맞는 `downsamplingSize`를 전달하며 이미지 캐시와 화면 이탈 시 요청 취소 기능을 활용해 메모리와 네트워크 사용을 최적화한다.
- **PopupView**: 성공·안내·경고·오류 같은 사용자 피드백을 토스트·팝업·바텀시트로 표시할 때 사용한다. 기존 `FeedbackMessage`와 View의 `feedbackPopup(...)`을 우선 재사용하고, 표시 방식과 스타일은 `FeedbackPresentation`, `FeedbackStyle`로 지정한다.
- **SwiftyBeaver**: 개발 중 상태 확인과 요청·오류 로그에 사용한다. 기존 `AppLogger`의 `debug`, `info`, `warning`, `error` 등을 통해 기록해 공통 로그 형식과 빌드별 출력 수준을 유지한다.

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
