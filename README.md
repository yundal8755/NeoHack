# Rouf

사진과 시간으로 하루의 루틴을 만들고, 다른 사람의 루틴을 따라 하며 참여 기록을 공유하는 iOS 앱입니다.

## 주요 기능

- **계정 선택**: 서버의 테스트 계정을 선택하고 사용권과 인증 세션을 관리합니다.
- **루틴 탐색**: 최신순·좋아요순·참여자순으로 루틴을 조회하고 다음 목록을 불러옵니다.
- **루틴 작성·편집**: 사진, 시간, 제목, 내용을 카드로 구성해 루틴을 만들고 수정·삭제합니다.
- **루틴 참여**: 다른 사람의 루틴을 따라 하며 참여 내용을 작성합니다. 작성 중인 참여 기록은 임시 저장하고 복원할 수 있습니다.
- **참여 기록**: 참여자 목록과 결과를 확인하고 자신의 참여 기록을 수정·삭제합니다.
- **소셜 상호작용**: 루틴에 좋아요와 댓글을 남기고 댓글을 수정·삭제합니다.
- **프로필**: 내 프로필과 다른 사용자의 프로필, 작성·참여한 루틴을 확인합니다.

## 아키텍처

### 화면 상태 관리: MVI

```text
사용자 입력 → Action → Store → Reducer → State → View
                                  ↓
                                Effect
                                  ↓
                         비동기 작업 → 결과 Action
```

View는 State를 표시하고 Action을 보냅니다. Reducer는 상태 변경과 Effect를 정의하며, Store가 상태와 비동기 Effect의 실행·취소를 관리합니다. Repository는 Reducer 생성 시 주입합니다.

### 서버 데이터 흐름

```text
요청: Presentation → Domain Repository 프로토콜 → Data Repository 구현 → 요청 DTO → Endpoint → 서버
응답: 서버 → 응답 DTO → Mapper → Entity → 결과 Action → State → View
```

- **Presentation**: SwiftUI 화면과 화면별 Reducer를 둡니다. UI는 Entity와 Repository 프로토콜을 사용합니다.
- **Domain**: Entity, 입력 모델, Repository 프로토콜을 정의합니다. 서버 응답 구조나 네트워크 라이브러리에 의존하지 않습니다.
- **Data**: 도메인별 DTO, Endpoint, Mapper, Repository 구현체를 둡니다. DTO를 Entity로 변환하고 요청·응답 오류를 처리합니다.
- **App / Core**: AppContainer에서 의존성을 조립하고 네트워크, 인증, 이미지, 피드백, 디자인 토큰 등 공통 코드를 제공합니다.

DTO는 Data 내부에서 처리하며 Repository 프로토콜의 입력·반환 타입이나 UI 상태에 노출하지 않습니다. 일반 실행은 서버 Repository를 사용하고 Mock은 Preview와 테스트에서 사용합니다.

### 폴더 구조

```text
Rouf/
├── App/                    # 앱 진입점, 의존성 조립, 디자인 토큰
├── Core/                   # 네트워크·이미지·피드백 등 공통 코드
├── Data/                   # 도메인별 DTO·Endpoint·Mapper·RepositoryImpl
│   ├── User/
│   ├── Routine/
│   ├── RoutineComment/
│   └── Image/
├── Domain/                 # Entity·입력 모델·Repository 프로토콜
├── Presentation/           # 화면·Reducer·화면 전환
└── Resource/               # 이미지·폰트 리소스
Packages/RoufCore/Sources/
├── MVICore/                # Store·Reducer·Effect
├── RoufCore/               # 공통 모델과 독립 실행 가능한 Reducer
├── RoufMocks/              # 테스트·Preview용 의존성
└── MVITestSupport/         # Reducer 테스트 도구
RoufSnapshotTests/          # 스냅샷·Data/Domain 테스트
RoufUITests/                # UI 흐름 테스트
```

공통 MVI와 일부 Reducer는 로컬 Swift Package로 분리되어 있어 시뮬레이터 없이 로직 테스트를 실행할 수 있습니다. 앱 Domain에 의존하는 화면 로직과 외부 라이브러리 구현체는 앱 타깃에 둡니다.

## 주요 기술

| 기술 | 사용 목적 |
| --- | --- |
| SwiftUI | 화면과 상태 기반 UI |
| 로컬 Swift Package | MVI 코어와 공통 로직 분리 |
| Alamofire | API 요청·인증 헤더·응답 처리 |
| Kingfisher | 원격 이미지 캐시·다운샘플링 |
| PopupView | 토스트·팝업·바텀시트 피드백 |
| SwiftyBeaver | 공통 개발 로그 |
| Swift Testing / XCTest / SnapshotTesting | 로직·데이터·화면 테스트 |

디자인 토큰과 공통 컴포넌트를 우선 재사용하며 기본 폰트는 Pretendard를 사용합니다.

## 개발 환경과 실행

- iOS 18 이상
- Xcode 26.2 이상

1. `Config/AppConfig.local.example.xcconfig`를 `Config/AppConfig.local.xcconfig`로 복사합니다.
2. 별도로 공유받은 서버 주소를 `API_BASE_URL`에 입력합니다. xcconfig의 URL에서 `//`는 `/$()/`로 표기합니다(예: `https:/$()/api.example.com`). 실기기 서명이 필요하면 본인의 `DEVELOPMENT_TEAM`도 설정합니다.
3. `Rouf.xcodeproj`를 열고 `Rouf` 스킴으로 빌드·실행합니다.

실제 서버·Swagger·ERD 주소와 개인 서명 설정은 Git에서 제외되는 로컬 파일에 보관합니다. 인증 토큰, 개인 이메일, 인증서, `.env` 파일은 커밋하지 않습니다.

## 테스트

```bash
scripts/test.sh        # 로컬 패키지의 로직 테스트
scripts/test.sh app    # 앱 스냅샷·UI 테스트 (시뮬레이터 필요)
```

선택적으로 `git config core.hooksPath .githooks`를 실행하면 저장소의 커밋·push 검사 훅을 활성화할 수 있습니다. 테스트 실행 조건과 도구는 [테스트 가이드](Docs/Testing.md)를 참고합니다.

## 관련 문서

- [아키텍처와 데이터 흐름](Docs/CleanArchitecture.md)
- [서버 연결과 데이터 계약](Docs/APICollaboration.md)
- [역할과 작업 흐름](Docs/IOSDeveloperHandoff.md)
- [테스트 가이드](Docs/Testing.md)
- [AI 개발 지침](AGENTS.md)
