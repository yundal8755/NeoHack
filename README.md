# HackertonBoilerplate

SwiftUI 해커톤 스타터입니다. iOS 18 이상에서 홈과 설정 탭으로 시작합니다.

## 실행

Xcode에서 `HackertonBoilerplate.xcodeproj`를 열고 `HackertonBoilerplate` 스킴을 선택해 시뮬레이터에서 실행합니다. 시작 화면에는 로그인이나 서버 설정이 필요하지 않습니다.

## API 연결

서버 주소가 확정되면 `Config/AppConfig.local.example.xcconfig`를 `Config/AppConfig.local.xcconfig`로 복사하고 `API_BASE_URL`에 주소를 설정합니다. 포트가 필요한 경우 URL에 포함합니다. xcconfig에서 URL의 `//`는 `/$()/`로 표기합니다. 로컬 파일은 Git에서 제외됩니다.

`Data`의 기능별 DTO, Endpoint, Mapper, Repository를 새 API 계약에 맞춰 사용합니다. `Core/Network`의 Alamofire 기반 `NetworkManager`는 `AppContainer`에서 주입합니다. `Core/MVICore`의 Store, Reducer, Effect는 상태가 필요한 신규 화면에 사용할 수 있습니다.

## 폰트

기본값은 Pretendard입니다. 다른 폰트를 쓰려면 폰트 파일을 앱 리소스에 포함하고 `Info.plist`의 `UIAppFonts`에 등록한 뒤 `AppFont`의 굵기별 PostScript 이름을 변경합니다. UI는 기존 폰트 토큰을 그대로 참조할 수 있습니다.

## Figma

구현할 프레임을 선택한 상태에서 Dev Mode 링크를 복사해 요청에 붙여넣습니다. 프레임 접근 권한이 필요합니다. 구현 절차는 [AGENTS.md](AGENTS.md), 프로젝트 구조와 협업 규칙은 [iOS 개발 가이드](Docs/IOSDeveloperHandoff.md)를 참고하세요.

# NeoHack
