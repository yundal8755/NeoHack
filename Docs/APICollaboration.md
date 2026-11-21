# 서버 연결과 데이터 전달

## 서버 명세

- API Base URL: https://api.example.invalid/
- [Swagger UI](https://api.example.invalid/swagger-ui/index.html)
- [OpenAPI JSON](https://api.example.invalid/v3/api-docs)
- [ERD](https://erd.example.invalid/share/REDACTED_ERD)

기본 서버는 Config/AppConfig.xcconfig, 개인 서버 변경은 Git에서 제외되는 Config/AppConfig.local.xcconfig에서 관리한다.

## 구현 범위 — 2026-11-22

| 도메인 | API | Repository 메서드 |
| --- | --- | --- |
| User | GET·POST /api/users, GET /api/users/me | list, create(nickname:), me |
| Routine | GET·POST /api/routines, GET·PUT·DELETE /api/routines/{routineId} | list(query:), detail(id:), create(input:), update(id:input:), delete(id:) |
| RoutineComment | GET·POST /api/routines/{routineId}/comments, PATCH·DELETE /api/routines/{routineId}/comments/{commentId} | list, create, update, delete |
| Image | POST /api/images, GET /api/images/{imageId} | upload(input:), data(id:) |

Data·Domain은 앱 소스에 도메인별로 배치한다. 요청 DTO는 Request, 응답 DTO는 Response 폴더에 둔다. 본문이 없는 조회·삭제에는 빈 DTO를 만들지 않는다. 루틴 생성·수정, 댓글 생성·수정은 같은 요청 DTO를 공유한다. ImageUploadRequestDTO는 JSON이 아닌 multipart의 file 파트다.

네 도메인의 DTO·Endpoint·Mapper·Entity·Repository protocol과 Impl까지 준비했다. Presentation·기존 mock·AppContainer 연결은 하지 않았다. 이전 Example DTO는 패키지에 그대로 남겨두며 현재 API용으로 사용하지 않는다. 최신 Swagger의 Example Create는 nickname을 참조하지만 기존 예제 DTO는 name이므로 별도 정리 전 실서버 호출에 사용하면 안 된다. health도 이번 범위에서 제외한다.

## 인증과 데이터 계약

- 루틴 목록·상세 및 이미지 조회는 공개 요청이다. 나머지 서비스 요청은 X-Device-Token이 필요하다.
- Repository 생성 시 토큰 공급 함수를 주입한다. 생성·Keychain 저장·사용자 생성 자동화는 이번 범위가 아니다. Bearer 토큰으로 대신 보내지 않는다.
- 응답은 isSuccess·code·message·result 봉투이며 성공 여부와 결과를 확인한 뒤 Entity로 매핑한다. 삭제의 result 스키마는 미정이므로 사용하지 않는다.
- DTO의 응답 필수 여부는 Swagger를 따른다. Entity에 필요한 핵심 값 누락과 잘못된 날짜·URL은 오류다. 기본값으로 숨기지 않는다.
- 루틴 목록은 sort(latest/likes/participants), authorId, cursor, size(1~50, 기본 20)를 받는다. 다음 페이지 정보는 RoutinePageEntity에 유지한다.
- 루틴 저장 입력은 title·content·순서가 있는 cards이며 각 카드에 업로드된 imageId·title·content·HH:mm time을 받는다. 업로드와 저장의 결합은 호출자가 나중에 구성한다.
- GET 이미지 응답은 원본 Data로 처리한다. UI 표시에서는 Kingfisher를 사용한다.

### 서버 확인이 필요한 항목

- Save.cards는 설명이 1~10개지만 minItems는 0이다. 현재 0~10개를 허용하며 UI 제한은 변경하지 않았다.
- CommentBody.content는 설명이 1~50자지만 minLength는 0이다. 현재 0~50자를 허용한다.
- 응답 대부분에 required가 없다. 식별자·핵심 값의 실제 보장 여부는 서버와 확인해야 한다.
- 기존 화면의 스텝 4개·소개 100자 제한과 서버의 10개·500자 제한은 다르다. 이번 작업에서 화면 정책은 바꾸지 않는다.

## 검증과 이후 연결

현재는 URLProtocol 대체 응답으로 요청 형식·인증·multipart·DTO·Mapper·Repository 반환·오류 전달을 검증한다. 실제 서버의 생성·수정·삭제는 실행하지 않는다.

UI 연결 시 Entity와 Repository 인터페이스를 공유하고 Reducer의 모듈 위치를 정리한 뒤 주입한다. UI 계층에는 DTO를 노출하지 않는다. 자세한 구조는 [아키텍처 가이드](CleanArchitecture.md)를 따른다.
