# Architecture Guide

## 앱 구조

앱 소스의 App·Core와 같은 레벨에 Data·Domain을 둔다. AppContainer가 계정별 Repository를 구성하고 Presentation의 홈·상세 Reducer에 주입한다.

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
  Presentation/                      서버 Entity를 표시하는 View와 MVI Reducer
```

Domain은 Foundation만 사용하며 Data·Alamofire·DTO를 참조하지 않는다. Repository 프로토콜에는 DTO를 노출하지 않는다. 입력은 기본 타입이나 Domain 입력 모델, 출력은 Entity·목록·페이지·Void 또는 이미지 원본 Data다.

## 요청과 응답

```text
Domain 입력 → RepositoryImpl → 요청 DTO → Endpoint → NetworkManager → 서버
서버 → 응답 DTO → 성공 여부 확인 → Mapper → Domain Entity
```

- RepositoryImpl은 NetworkManager와 `accessToken: () throws -> String`을 생성자로 받는다. 생성 자체로 요청하거나 토큰을 생성·저장하지 않는다.
- ProfileAccounts가 서버의 계정을 점유하고 세션 토큰을 메모리에 보관한다. AppContainer는 인증 Repository에 해당 세션의 Bearer 토큰을 전달한다. ProfileAccounts는 30초마다 계정 사용권을 갱신한다. 갱신이 중단되면 사용권은 서버에서 만료된다.
- multipart 업로드는 NetworkManager의 공통 Alamofire Session을 사용한다. 작성 화면은 사진 업로드 결과를 카드 순서대로 모아 루틴을 저장한다. 다시 시도할 때 이미 받은 imageId를 재사용한다.
- APIResponseDTO가 isSuccess와 필수 result를 확인한다. 삭제는 APIDeleteResponseDTO로 미정의 result를 무시한다.
- 응답 DTO의 Optional은 Swagger required를 따른다. Mapper는 식별자와 핵심 값(사용자 닉네임·루틴 제목·댓글 본문) 누락을 오류로 처리한다. 나머지 선택 값을 임의의 0·빈 문자열로 채우지 않는다.
- 날짜는 ISO 8601(소수 초 유무 지원)의 Date로 읽는다. 시간대 없는 서버 날짜는 Asia/Seoul로 해석한다. 이미지 URL은 HTTP/HTTPS URL로 변환한다. 잘못된 값은 DataContractError로 전달한다.
- 요청 검증은 명세의 길이·페이지 크기·ULID·HH:mm 제약을 따른다. 설명과 스키마의 최소 개수·길이가 충돌하는 경우는 API 협업 문서에 기록한다.

## UI 경계와 기존 패키지

View는 State와 Action, Reducer는 주입받은 Repository 프로토콜과 Entity를 사용하는 원칙을 유지한다. View·Reducer·State·Action은 DTO·Mapper·RepositoryImpl·Endpoint를 직접 사용하지 않는다. 원격 이미지 표시는 기존 NetworkImageView와 Kingfisher를 사용한다.

홈·상세 Reducer는 앱 Domain을 사용하므로 앱 타깃에 둔다. 공통 MVICore와 루틴 작성 폼·입력 모델은 로컬 패키지에 둔다. 화면 fixture는 DEBUG의 테스트 실행과 Preview에서 사용한다.

새 Data·Domain 코드는 앱 타깃에 있으므로 시뮬레이터에서 테스트한다. 기존 패키지 테스트는 계속 macOS에서 실행한다. 자세한 실행법은 [테스트 가이드](Testing.md)를 따른다.
