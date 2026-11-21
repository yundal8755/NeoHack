# Architecture Guide

SwiftUI 화면은 공통 MVI를 사용하고, API 응답은 DTO → Mapper → Entity로 변환해 화면에 전달한다. 서비스별 API와 모델은 실제 기능을 구현할 때 추가하며, 기능이 없는 상태에서는 빈 폴더나 예제 구현을 만들지 않는다.

Data layer와 Entity 구성은 서버 연결 담당이 맡고, UI 담당은 전달받은 Entity를 화면에 연결한다. 구체적인 역할은 [역할과 작업 흐름](IOSDeveloperHandoff.md)을 따른다.

## 데이터 흐름

```text
요청: View → Action → Reducer의 Effect → Repository → Endpoint / NetworkManager → 서버
응답: 서버 JSON → DTO → Mapper → Entity → Action → Reducer의 State → View
```

- View는 State를 표시하고 사용자 입력을 Action으로 전달한다.
- Reducer는 상태를 변경하며, API 호출 같은 비동기 작업은 Effect에서 실행한다.
- Repository는 Endpoint로 요청하고 응답 DTO를 Mapper에 전달해 Entity를 반환한다.
- Mapper는 네트워크 호출이나 화면 상태 변경 없이 데이터만 변환한다.
- View와 Reducer는 DTO를 직접 생성·참조·인코딩·디코딩하거나 URL을 조립하지 않는다.

## UI와 Data layer의 경계

- View는 State를 표시하고 Action을 보낸다. Repository 호출은 Reducer의 Effect에서 수행한다.
- Reducer는 init으로 주입받은 Repository 프로토콜을 사용하고, 반환받은 Entity를 State에 반영한다. Repository 구현체, Endpoint, NetworkManager, Mapper를 직접 사용하지 않는다.
- State와 Action의 데이터 타입에는 Entity와 필요한 기본 타입을 사용한다. 서버 요청·응답 DTO와 서버 응답 wrapper를 보관하지 않는다.
- Repository 프로토콜은 DTO 타입을 입력·반환값으로 노출하지 않는다. UI에는 호출할 메서드, 입력값, 반환 Entity, 오류 처리 방식만 공유한다.
- 요청은 UI의 입력값을 기본 타입이나 앱 입력 모델로 받아 Repository 구현체에서 요청 DTO를 만든다. 모든 입력을 하나의 Entity로 감쌀 필요는 없다.
- 응답은 Repository 구현체가 DTO를 디코딩하고 Mapper로 Entity로 변환한 뒤 반환한다. 서버 필드명과 응답 형식의 변경은 Data layer에서 처리한다.

현재는 DTO 준비 단계이며 Entity는 아직 생성하지 않는다. Entity가 준비되지 않았다는 이유로 DTO를 화면에 직접 연결하지 않는다. 위 내용은 이후 UI 연동 시 지킬 경계이며, Entity·Mapper·Repository를 지금 추가하라는 의미가 아니다.

## 기능을 추가할 때의 폴더 구조

아래 경로의 `<Feature>`는 새 서비스의 실제 기능 이름으로 바꾼다.

로직은 로컬 패키지 `Packages/HackertonCore`에 두고 `swift test`로 빠르게 검증한다. SwiftUI View와 외부 라이브러리를 쓰는 구현체는 앱 타깃에 둔다. 테스트 방법은 [테스트 가이드](Testing.md)를 따른다.

```text
Packages/HackertonCore/Sources/
  MVICore/                         Reducer, Effect, Store
  HackertonCore/
    Entity/<Feature>/<Feature>.swift
    Domain/<Feature>Repository.swift       Repository 프로토콜
    DataModel/<Feature>/
      <Feature>DTO.swift
      <Feature>Mapper.swift
    Feature/<Feature>/<Feature>Reducer.swift
  HackertonMocks/Mock<Feature>Repository.swift

HackertonBoilerplate/
  App/
    AppContainer.swift             실행 인자에 따라 실제 구현체 또는 Mock 주입
  Core/
    Network/
    Components/
  Data/<Feature>/
    <Feature>Endpoint.swift
    <Feature>Repository.swift      Repository 프로토콜의 실제 구현체
  Presentation/<Feature>/
    <Feature>View.swift
```

## 각 구성의 책임

| 구성 | 책임 |
| --- | --- |
| Endpoint | `TargetType`을 구현해 HTTP 메서드, 경로, 파라미터, 본문, 헤더, 인증 필요 여부를 정의한다. |
| NetworkManager | 공통 요청 실행, JSON 디코딩, 네트워크 오류와 인증 처리를 담당한다. |
| DTO | 서버 요청·응답 형식을 표현한다. 응답 DTO는 `Decodable`, 요청 DTO는 `Encodable`을 사용한다. |
| Mapper | DTO의 필드명, 타입, 날짜, 선택값 등을 앱에서 사용할 Entity로 변환한다. |
| Entity | 서버 응답 형식과 분리된 앱 모델이다. SwiftUI, Alamofire, DTO에 의존하지 않는다. |
| Repository | 프로토콜은 패키지 `Domain`에, 구현체는 앱 `Data`에 둔다. 프로토콜에는 DTO를 노출하지 않고, 구현체가 요청 DTO 생성과 API 호출, 성공·실패 판단, DTO → Entity 변환을 조합한다. 화면에는 Entity 또는 Entity 목록·페이지를 반환한다. |
| Reducer | 패키지 `Feature`에 둔다. State와 Action을 내부에 정의하고, init으로 받은 Repository 결과를 State에 반영한다. |
| AppContainer | NetworkManager와 저장소, 실제 기능의 Repository를 생성해 주입한다. `-mock-mode` 실행 인자가 있으면 Mock을 주입한다. |

앱의 `Data`는 `Core/Network`와 패키지의 DTO·Mapper·Entity를 사용한다. `Presentation`은 패키지의 Reducer와 Entity를 사용하고, `Core/Network`는 서비스별 DTO나 Entity를 참조하지 않는다. 패키지는 앱 타깃을 참조하지 않는다.

## API 계약과 변환 규칙

- API 경로, 필드명, 성공 조건, 오류 형식은 새 서버의 계약에 맞춰 정의한다. 이전 서비스의 응답 포맷을 전제하지 않는다.
- 성공 응답을 감싸는 공통 필드가 필요하면 실제 계약에 맞는 DTO를 `Data`에 추가한다.
- 공통 응답 디코더는 snake_case를 camelCase로 변환한다. 요청 DTO는 속성명 또는 `CodingKeys`에 따라 인코딩되므로 서버 키 이름을 확인한다.
- 필수 필드가 없거나 변환에 실패하면 오류를 전달한다. 임의의 빈 문자열이나 0으로 잘못된 응답을 숨기지 않는다.
- 기본값과 선택값 처리는 API 계약과 화면 요구가 정해진 경우에만 Mapper에 둔다.
- 신규 Mapper에 타입·날짜 변환이나 분기가 있다면 실제 응답 예시와 잘못된 입력을 검증하는 작은 테스트를 추가한다.

## 공통 인증 기반

- `TokenStoring`과 `KeychainTokenStore`는 토큰 저장·삭제를 담당한다.
- `AuthInterceptor`는 인증이 필요한 요청에 Bearer 헤더를 붙인다.
- 실제 로그인 API, 요청·응답 DTO, 로그인 화면은 새 서비스에서 추가한다.
- 토큰 갱신이 필요하면 `AccessTokenRefreshing` 구현을 주입한다. 기본 AppContainer에는 갱신 API가 연결돼 있지 않다.
