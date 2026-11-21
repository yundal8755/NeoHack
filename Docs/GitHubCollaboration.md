# GitHub Collaboration Rules

해커톤에서는 속도와 발표 안정성이 가장 중요합니다. 이 문서는 충돌을 줄이고, 빠르게 병합하고, 항상 발표 가능한 브랜치를 유지하기 위한 기본 규칙입니다.

## Branch Strategy

기본 전략:

- `main`: 항상 빌드 가능한 발표 버전
- `feature/*`: 기능 개발 브랜치

시간이 충분한 팀만 선택:

- `main`
- `develop`
- `feature/*`

추천 예시:

- `feature/home-ui`
- `feature/login-api`
- `feature/search-flow`
- `fix/token-storage`

## Commit Message Rules

- `feat:` 새로운 기능
- `fix:` 버그 수정
- `design:` UI 수정
- `refactor:` 리팩토링
- `chore:` 설정/패키지 변경
- `docs:` 문서 수정

예시:

- `feat: add home mvvm sample`
- `fix: handle empty search results`
- `design: update primary button spacing`
- `chore: add alamofire package`

## PR Rules

- PR은 짧게 유지합니다.
- 리뷰는 5분 안에 끝날 수 있어야 합니다.
- UI 변경은 스크린샷 첨부
- API 변경은 endpoint 명시
- mock 데이터나 하드코딩이 있으면 PR 설명에 적습니다.
- `main` 병합 전 반드시 빌드 확인

## Conflict Avoidance

- `Presentation/<FeatureName>` 단위로 나눠 작업합니다.
- 공통 구조 담당자 1명이 앱 진입점, 패키지, 공통 토큰 변경을 맡습니다.
- 화면 담당자는 가급적 자기 Feature 폴더만 수정합니다.
- 충돌이 잦은 파일은 한 명만 수정합니다.
- 큰 구조 변경은 팀 합의 없이 하지 않습니다.

## Issue Examples

- `[iOS] 홈 화면 UI 구현`
- `[iOS] 로그인 API 연결`
- `[Server] 로그인 API mock response 작성`
- `[Design] 공통 버튼 컴포넌트 정리`
- `[PM] 발표용 핵심 플로우 확정`

## Final Check Before Merge

- 앱이 빌드된다.
- 발표용 핵심 플로우가 직접 실행된다.
- Local DB, 오프라인 동기화, 과한 캐싱이 무의식적으로 추가되지 않았다.
- 새 API 기능은 Data endpoint/repository, Core/Network infrastructure, Domain, Presentation 경계를 지킨다.
- mock 응답을 쓰는 기능이 있다면 팀원이 알고 있다.
