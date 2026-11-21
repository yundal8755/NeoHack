# HackertonBoilerplate

- 화면 상태가 필요한 기능은 기존 MVI 코어를 사용한다. View와 Reducer를 기본으로 두고 State와 Action은 Reducer 내부에 정의한다.
- Figma 구현 요청은 프레임별 Dev Mode 링크의 fileKey와 node-id를 사용한다. 브랜치 링크는 브랜치 키를 사용하며 페이지 링크만 있으면 메타데이터에서 대상 프레임을 찾는다. 대상이 모호하거나 접근이 막히면 프레임 링크 또는 접근 권한을 요청한다.
- Figma 디자인→코드 및 SwiftUI 스킬을 읽고 Figma MCP에서 디자인 컨텍스트와 스크린샷을 확인한다. 컨텍스트 요청에는 clientLanguages=swift, clientFrameworks=swiftui를 지정한다.
- Figma의 변수, 타이포그래피, 간격, 컴포넌트 상태를 기존 AppFont, AppColor, AppSpacing, AppRadius와 공용 SwiftUI 컴포넌트에 매핑한다. 제공된 에셋은 앱 에셋 카탈로그에 등록한다. 실제 화면을 빌드한 뒤 시뮬레이터 스크린샷을 원본 프레임과 비교한다.
