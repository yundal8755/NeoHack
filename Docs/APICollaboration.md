# 서버 연결과 데이터 전달

Data layer와 Entity는 서버 연결 담당이 맡고, UI 담당은 전달받은 Entity를 화면에 연결합니다. 인원과 책임은 [역할과 작업 흐름](IOSDeveloperHandoff.md)을 따릅니다.

## 서버와 명세

- API Base URL: [https://api.example.invalid/](https://api.example.invalid/)
- Swagger: [Swagger UI](https://api.example.invalid/swagger-ui/index.html)
- OpenAPI JSON: [현재 API 명세](https://api.example.invalid/v3/api-docs)
- ERD: [WorksCove 공유 ERD](https://erd.example.invalid/share/REDACTED_ERD)

기본 서버 주소는 `Config/AppConfig.xcconfig`에서 관리합니다. 개인별 서버 변경은 Git에서 제외되는 `Config/AppConfig.local.xcconfig`에 둡니다.

## 현재 DTO 구현 범위

2026-11-21 확인한 Swagger에는 예제 생성·조회와 health 체크만 공개되어 있습니다. 현재 단계는 아래 3종의 DTO만 구현하며 Entity, Mapper, Endpoint, Repository는 추가하지 않습니다. ERD 테이블에서 미정 API의 DTO나 Entity를 추정하지 않습니다.

| API | 요청 | 응답 |
| --- | --- | --- |
| `POST /api/v1/examples` | `ExampleCreateRequestDTO` | `ExampleAPIResponseDTO` |
| `GET /api/v1/examples/{id}` | 경로 파라미터 `id: Int64` | `ExampleAPIResponseDTO` |
| `GET /health` | 없음 | 문자열이므로 별도 DTO 없음 |

DTO는 `Packages/HackertonCore/Sources/HackertonCore/DataModel/Example`에 둡니다.

| OpenAPI 스키마 | Swift 타입 | 필드 |
| --- | --- | --- |
| `Create` | `ExampleCreateRequestDTO` | 필수 `name: String` |
| `ExampleResponseDTO` | `ExampleResponseDTO` | `id: Int64?`, `name: String?` |
| `ApiResponseExampleResponseDTO` | `ExampleAPIResponseDTO` | `isSuccess: Bool?`, `code: String?`, `message: String?`, `result: ExampleResponseDTO?` |

요청 DTO는 `Encodable`, 응답 DTO는 `Decodable`을 사용하며 모두 `Equatable`, `Sendable`을 채택합니다. 응답 필드는 명세에 `required`가 지정되어 있지 않아 Optional로 표현합니다. 명세에 없는 기본값이나 성공 판단 로직은 추가하지 않습니다.

## 서버 계약 확인

기능별로 다음 내용을 확인합니다.

- 요청 경로와 HTTP 메서드
- 경로·쿼리 파라미터와 요청 본문
- 성공 응답과 오류 응답의 실제 JSON 예시
- 인증 필요 여부와 오류 상태 코드
- 페이지네이션, 날짜 형식, 선택값·빈 결과의 의미

서버의 실제 계약을 기준으로 구현하며, 명세에 없는 API 경로나 응답 형식을 미리 전제하지 않습니다.

## Data layer 구현

- 아래는 이후 연동 시 지킬 규칙입니다. 현재 DTO 준비 단계에서 Entity·Mapper·Endpoint·Repository를 추가하지 않습니다.
- Endpoint가 요청을 정의하고 Repository가 공통 NetworkManager를 호출합니다.
- UI 계층(View·Reducer·State·Action)은 DTO를 알지 않으며, Repository 프로토콜의 입력·반환 타입에도 DTO를 노출하지 않습니다.
- UI 입력은 기본 타입이나 앱 입력 모델로 받고, Repository 구현체가 요청 DTO를 생성합니다.
- 서버 JSON을 DTO로 디코딩한 뒤 Mapper에서 Entity로 변환합니다.
- Entity는 화면에서 사용할 필드와 타입으로 구성합니다.
- 화면에는 DTO 대신 Entity를 반환합니다.
- Reducer는 주입받은 Repository 프로토콜을 통해 Entity를 받아 State를 변경하며, View는 State와 Action만 사용합니다.
- 구체적인 폴더 구조와 변환 규칙은 [아키텍처 가이드](CleanArchitecture.md)를 따릅니다.

## UI 담당에게 전달할 내용

- Entity의 필드·타입과 각 값의 의미
- 호출할 Repository 메서드와 파라미터
- 단건·목록·빈 결과·오류 처리 방식
- 서버 연결 전 UI 작업에 필요한 Entity 예시 데이터

Entity나 Repository 인터페이스가 변경되면 영향을 받는 UI 담당에게 공유합니다.

## 연동 테스트

서버 연결 담당이 실제 응답의 디코딩, DTO → Entity 매핑, 화면 표시를 확인합니다. 정상 응답뿐 아니라 빈 결과, 오류 응답, 필요한 경우 인증 실패도 확인합니다. UI 담당과 화면에서 사용하는 Entity의 필드·타입이 맞는지 확인합니다.
