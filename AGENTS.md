# 개발 지침

- 역할과 책임은 `Docs/IOSDeveloperHandoff.md`를 따른다. UI 개발 2명, 서버 연결·테스트·기타 작업 1명이며 담당자는 미정이다. 디자인시스템 컴포넌트 제작은 공통 책임이다.
- UI 담당은 Figma 구현과 Entity의 화면 연결을 맡고, 서버 연결 담당은 Data layer 전체와 Entity 구성·서버 연동·테스트를 맡는다.
- 화면 상태가 필요한 기능은 기존 MVI 코어를 사용한다. View와 Reducer를 기본으로 두고 State와 Action은 Reducer 내부에 정의한다.
- API 연동은 `Docs/CleanArchitecture.md`를 따른다. `Data/<Feature>`의 Endpoint와 Repository가 요청하고, DTO를 Mapper로 `Entity/<Feature>`의 모델로 변환한 뒤 화면에 전달한다. 서비스별 코드는 실제 기능을 구현할 때 추가한다.
- Figma 구현 요청은 프레임별 Dev Mode 링크의 fileKey와 node-id를 사용한다. 브랜치 링크는 브랜치 키를 사용하며 페이지 링크만 있으면 메타데이터에서 대상 프레임을 찾는다. 대상이 모호하거나 접근이 막히면 프레임 링크 또는 접근 권한을 요청한다.
- Figma 디자인→코드 및 SwiftUI 스킬을 읽고 Figma MCP에서 디자인 컨텍스트와 스크린샷을 확인한다. 컨텍스트 요청에는 clientLanguages=swift, clientFrameworks=swiftui를 지정한다.
- Figma의 변수, 타이포그래피, 간격, 컴포넌트 상태를 기존 AppFont, AppColor, AppSpacing, AppRadius와 공용 SwiftUI 컴포넌트에 매핑한다. 제공된 에셋은 앱 에셋 카탈로그에 등록한다. 실제 화면을 빌드한 뒤 시뮬레이터 스크린샷을 원본 프레임과 비교한다.

## 외부 라이브러리와 공통 코드

- 새 기능 구현 전 `Core`와 `App/Constant`의 기존 공통 코드를 먼저 확인하고 우선 재사용한다. 같은 역할의 컴포넌트나 유틸리티를 중복 구현하지 않는다.
- **Alamofire**: 서버 API 요청과 응답 처리에 사용한다. 기능별 Endpoint는 기존 `TargetType`을 구현하고, Repository는 AppContainer에서 주입받은 `NetworkManager`를 사용한다. 인증 헤더, 디코딩, 네트워크 오류 처리는 기존 `AuthInterceptor`, `CodableManager`, `NetworkError`를 재사용한다.
- **Kingfisher**: 원격 이미지 기능에 반드시 사용하고, 기존 `NetworkImageView`를 우선 재사용한다. 표시 크기에 맞는 `downsamplingSize`를 전달하며 이미지 캐시와 화면 이탈 시 요청 취소 기능을 활용해 메모리와 네트워크 사용을 최적화한다.
- **PopupView**: 성공·안내·경고·오류 같은 사용자 피드백을 토스트·팝업·바텀시트로 표시할 때 사용한다. 기존 `FeedbackMessage`와 View의 `feedbackPopup(...)`을 우선 재사용하고, 표시 방식과 스타일은 `FeedbackPresentation`, `FeedbackStyle`로 지정한다.
- **SwiftyBeaver**: 개발 중 상태 확인과 요청·오류 로그에 사용한다. 기존 `AppLogger`의 `debug`, `info`, `warning`, `error` 등을 통해 기록해 공통 로그 형식과 빌드별 출력 수준을 유지한다.
