# NeoHack

SwiftUI 보일러플레이트입니다. iOS 18 이상에서 홈·설정 탭으로 시작합니다. 역할은 UI 개발 2명, 서버 연결·테스트·기타 작업 1명으로 나누며, 담당자는 아직 정하지 않았습니다.

## 실행

Xcode에서 `HackertonBoilerplate.xcodeproj`를 열고 `HackertonBoilerplate` 스킴으로 시뮬레이터에서 실행합니다. 시작 화면에는 로그인이나 서버 설정이 필요하지 않습니다.

## 개발 방식

- 공통 디자인시스템 컴포넌트는 팀원 모두가 제작합니다.
- UI 담당은 Figma 링크를 기준으로 화면을 구현하고, Data layer에서 전달받은 Entity를 화면에 연결합니다.
- 서버 연결 담당은 Data layer 전체와 Entity 구성, 서버 연동·테스트·기타 작업을 맡습니다.
- 화면 상태는 공통 MVI를 사용하고, 서버 응답은 DTO → Mapper → Entity로 변환합니다.

## 테스트

```bash
scripts/test.sh        # 로직 테스트 (Packages/HackertonCore, swift test)
scripts/test.sh app    # 스냅샷 + UI 테스트 (시뮬레이터)
```

UI 테스트 로그를 보기 좋게 보려면 [xcbeautify](https://github.com/cpisciotta/xcbeautify) 설치를 권장합니다(선택). 설치하지 않아도 테스트는 똑같이 동작합니다.

```bash
brew install xcbeautify
```

자세한 내용은 [테스트 가이드](Docs/Testing.md)를 참고합니다.

## 서버 설정

기본 API 서버는 [https://api.example.invalid/](https://api.example.invalid/)이며 `Config/AppConfig.xcconfig`에 설정되어 있습니다. 다른 서버를 사용할 때만 `Config/AppConfig.local.example.xcconfig`를 `Config/AppConfig.local.xcconfig`로 복사해 `API_BASE_URL`을 덮어씁니다. xcconfig의 URL에서 `//`는 `/$()/`로 표기합니다. 로컬 설정 파일은 Git에서 제외됩니다.

Swagger·ERD 링크와 현재 DTO 범위는 [서버 연결 가이드](Docs/APICollaboration.md)를 참고합니다.

## 디자인 구현

기본 폰트는 Pretendard이며, 색상·폰트·간격·모서리 값은 기존 App 토큰을 사용합니다. 폰트를 바꾸면 리소스, `Info.plist`의 `UIAppFonts`, `AppFont`를 함께 변경합니다.

Figma에서 구현할 프레임의 Dev Mode 링크를 복사해 구현 요청에 붙여 넣습니다. 기존 공통 컴포넌트를 먼저 사용하고, 필요한 컴포넌트는 공통으로 제작합니다.

## 문서

- [역할과 작업 흐름](Docs/IOSDeveloperHandoff.md)
- [아키텍처와 데이터 흐름](Docs/CleanArchitecture.md)
- [서버 연결과 데이터 전달](Docs/APICollaboration.md)
- [테스트 가이드](Docs/Testing.md)
- [AI 개발 지침](AGENTS.md)
