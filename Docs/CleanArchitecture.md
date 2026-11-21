# Architecture Guide

## 현재 준비 범위

앱 소스의 App·Core와 같은 레벨에 Data·Domain을 둔다. User·Routine·RoutineComment·Image의 API와 Entity까지 구현하며 Presentation, 기존 mock 데이터, AppContainer의 주입 흐름은 변경하지 않는다.

```text
HackertonBoilerplate/
  App/
  Core/Network/
  Data/
    Common/                          응답 봉투, 매핑 오류·변환, 공통 TargetType 구현
    <DomainName>/
      DTO/Request/                   JSON Encodable 또는 multipart 파일 모델
      DTO/Response/                  서버 응답 Decodable
      Endpoint/                      메서드·경로·쿼리·헤더·본문
      Mapper/                        DTO → Entity, Domain 입력 → 요청 DTO
      Repository/                    <DomainName>RepositoryImpl
  Domain/<DomainName>/
    Entity/                          Foundation 기반 앱 모델
    Input/                           필요한 생성·조회 입력 모델
    Repository/                      <DomainName>Repository protocol
  Presentation/                      기존 화면과 mock 유지
```

Domain은 Foundation만 사용하며 Data·Alamofire·DTO를 참조하지 않는다. Repository 프로토콜에는 DTO를 노출하지 않는다. 입력은 기본 타입이나 Domain 입력 모델, 출력은 Entity·목록·페이지·Void 또는 이미지 원본 Data다.

## 요청과 응답

```text
Domain 입력 → RepositoryImpl → 요청 DTO → Endpoint → NetworkManager → 서버
서버 → 응답 DTO → 성공 여부 확인 → Mapper → Domain Entity
```

- RepositoryImpl은 NetworkManager와 `deviceToken: () throws -> String`을 생성자로 받는다. 생성 자체로 요청하거나 토큰을 생성·저장하지 않는다.
- 토큰이 필요한 요청만 X-Device-Token을 전달한다. 현재 서비스는 기존 Bearer 인증·갱신과 별개다. 빈 토큰과 잘못된 헤더 값은 요청 전에 거부한다.
- multipart 업로드는 NetworkManager의 공통 Alamofire Session을 사용한다. 루틴 저장은 업로드된 imageId를 받으며 이미지 업로드를 자동 실행하지 않는다.
- APIResponseDTO가 isSuccess와 필수 result를 확인한다. 삭제는 APIDeleteResponseDTO로 미정의 result를 무시한다.
- 응답 DTO의 Optional은 Swagger required를 따른다. Mapper는 식별자와 핵심 값(사용자 닉네임·루틴 제목·댓글 본문) 누락을 오류로 처리한다. 나머지 선택 값을 임의의 0·빈 문자열로 채우지 않는다.
- 날짜는 ISO 8601(소수 초 유무 지원)의 Date, 이미지 URL은 HTTP/HTTPS URL로 변환한다. 잘못된 값은 DataContractError로 전달한다.
- 요청 검증은 명세의 길이·페이지 크기·ULID·HH:mm 제약을 따른다. 설명과 스키마의 최소 개수·길이가 충돌하는 경우는 API 협업 문서에 기록한다.

## UI 경계와 기존 패키지

View는 State와 Action, Reducer는 주입받은 Repository 프로토콜과 Entity를 사용하는 원칙을 유지한다. View·Reducer·State·Action은 DTO·Mapper·RepositoryImpl·Endpoint를 직접 사용하지 않는다. 원격 이미지 표시는 기존 NetworkImageView와 Kingfisher를 사용한다.

이번 작업에서 UI는 연결하지 않는다. 기존 MVICore·HackertonCore의 Reducer·RoutineDraft·TimeOfDay·TokenStoring·Example DTO와 관련 테스트는 이동하지 않는다. 패키지는 앱 Domain을 참조할 수 없으므로, 향후 실제 UI 연결 단계에서 해당 Reducer의 위치 또는 Domain 모듈 분리를 먼저 결정해야 한다. 중복 Entity를 만들어 해결하지 않는다.

새 Data·Domain 코드는 앱 타깃에 있으므로 시뮬레이터에서 테스트한다. 기존 패키지 테스트는 계속 macOS에서 실행한다. 자세한 실행법은 [테스트 가이드](Testing.md)를 따른다.
