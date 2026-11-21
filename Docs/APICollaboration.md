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
| User | GET·POST /api/users, GET·PATCH /api/users/me | list, create(nickname:bio:), me, updateProfile |
| Routine | GET·POST /api/routines, GET·PUT·DELETE /api/routines/{routineId} | list(query:), detail(id:), create(input:), update(id:input:), delete(id:) |
| Routine 상호작용 | GET /interactions, PUT·DELETE /like, PUT·DELETE /participation, PUT /participation/completion (루틴 ID 뒤 경로) | interactions(id:change:) |
| RoutineComment | GET·POST /api/routines/{routineId}/comments, PATCH·DELETE /api/routines/{routineId}/comments/{commentId} | list, create, update, delete |
| Image | POST /api/images, POST /api/images/profile, GET /api/images/{imageId} | upload(input:), uploadProfile(input:), data(id:) |

Data·Domain은 앱 소스에 도메인별로 배치한다. 요청 DTO는 Request, 응답 DTO는 Response 폴더에 둔다. 본문이 없는 조회·삭제에는 빈 DTO를 만들지 않는다. 루틴 생성·수정, 댓글 생성·수정은 같은 요청 DTO를 공유한다. ImageUploadRequestDTO는 JSON이 아닌 multipart의 file 파트다.

앱은 계정을 선택한 뒤 홈·상세·작성·마이프로필을 실제 서버에 연결한다. 사용자 생성 Repository는 유지하며 앱 초기 진입은 기존 사용자 선택으로 구성한다. 마이프로필 편집에서 닉네임·소개·프로필 사진을 변경할 수 있다.

## 인증과 데이터 계약

- 루틴 목록·상세 및 이미지 조회는 공개 요청이다. 댓글 목록은 토큰이 선택이지만 앱에서 선택 계정의 헤더를 보내 isMine을 받는다.
- 첫 연결에서 GET /api/users로 프로필을 조회하고 GET /api/users/me로 선택을 확인한다. 이후 인증 요청은 검증된 X-Device-Token과 X-User-Id를 사용한다.
- 응답은 isSuccess·code·message·result 봉투이며 성공 여부와 결과를 확인한 뒤 Entity로 매핑한다. 삭제의 result 스키마는 미정이므로 사용하지 않는다.
- DTO의 응답 필수 여부는 Swagger를 따른다. Entity에 필요한 핵심 값 누락과 잘못된 날짜·URL은 오류다. 기본값으로 숨기지 않는다.
- 루틴 목록은 sort(latest/likes/participants), authorId, cursor, size(1~50, 기본 20)를 받는다. 다음 페이지 정보는 RoutinePageEntity에 유지한다.
- 루틴 저장 입력은 title·content·순서가 있는 cards이며 각 카드에 업로드된 imageId·title·content·HH:mm time을 받는다. 작성 화면은 업로드 성공 ID를 보존해 재시도 시 재사용한다.
- GET 이미지 응답은 원본 Data로 처리한다. UI 표시에서는 Kingfisher를 사용한다.

### 서버 확인이 필요한 항목

- Save.cards는 설명이 1~10개지만 minItems는 0이다. 현재 0~10개를 허용하며 UI 제한은 변경하지 않았다.
- CommentBody.content는 설명이 1~50자지만 minLength는 0이다. 현재 0~50자를 허용한다.
- 응답 대부분에 required가 없다. 식별자·핵심 값의 실제 보장 여부는 서버와 확인해야 한다.
- 기존 화면의 스텝 4개·소개 100자 제한과 서버의 10개·500자 제한은 다르다. 이번 작업에서 화면 정책은 바꾸지 않는다.

## 검증

URLProtocol 대체 응답은 요청 형식, 선택 계정 헤더, multipart, 매핑, Repository 반환과 오류를 검증한다. 화면의 DTO 경계는 [아키텍처 가이드](CleanArchitecture.md)를 따른다.

## 사용자 프로필 DTO 갱신 — 2026-11-22

- 최신 GET /api/users/me는 ApiResponseUserResponse → UserResponse를 반환한다. GET /api/users와 POST /api/users도 같은 프로필 모델을 사용한다. 앱의 Swift 타입명 UserResponseDTO는 유지한다.
- 응답에 bio: String? (마이페이지 한 줄 소개)가 추가됐다. 누락·null은 nil, 빈 문자열은 그대로 보존하고 UserMapper → UserEntity.bio로 전달한다.
- 생성 요청 Create에도 선택 bio가 추가됐다. UserCreateRequestDTO와 Repository.create(nickname:bio:)로 전달하며 nil이면 JSON 키를 생략한다. 기존 create(nickname:) 호출도 유지한다.
- bio는 최대 100자이며 줄바꿈(CR·LF·VT·FF·NEL·LS·PS)을 허용하지 않는다. Endpoint에서 검증한다.
- 다른 도메인의 미해결 명세 변경이 있어 전체 OpenAPI 기준 파일은 이번 사용자 프로필 변경만으로 갱신하지 않는다.


프로필 수정은 변경한 필드만 보낸다. 한 줄 소개를 비우면 `bio: null`로 보내 삭제하고, 소개를 그대로 두면 키를 생략한다. 수정 닉네임은 2~10자, 소개는 줄바꿈 없이 최대 50자다. 프로필 사진은 `POST /api/images/profile`에 최대 5MB의 multipart `file`을 전송하고 응답의 `imageId`를 수정 요청의 `profileImagePublicId`로 사용한다.
