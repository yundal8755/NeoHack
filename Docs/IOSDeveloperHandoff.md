# 역할과 작업 흐름

담당자는 미정입니다. 아래는 인원 구성과 역할별 책임이며, 특정 팀원에게 배정한 내용이 아닙니다.

## dev 반영 방식

- 개인 작업 브랜치에서 작업하고 커밋·push합니다.
- `dev` 반영 시 PR 작성, 팀원 코드 리뷰, 승인 대기를 필수로 하지 않습니다.
- 작업자가 최신 원격 `dev`를 로컬에 가져와 개인 작업 브랜치를 병합하고 원격 `dev`로 직접 push합니다.
- 개인 브랜치에 push하는 것과 `dev`에 반영하는 것은 별도 작업입니다. 아래 명령의 `feature/my-work`는 본인의 실제 작업 브랜치명으로 바꿉니다.

```bash
git switch dev
git pull --ff-only origin dev
git merge feature/my-work
git push origin dev
```

충돌이 발생하면 작업자가 해결하고 병합을 완료한 뒤 push합니다.

## 역할별 책임

| 역할 | 인원 | 책임 |
| --- | --- | --- |
| UI 개발 | 2명 | Figma 디자인 구현, Data layer에서 전달받은 Entity를 UI에 연결 |
| 서버 연결·테스트·기타 작업 | 1명 | Data layer 전체 구현, 서버 데이터 연결, Entity 구성, 연동 테스트와 기타 작업 |

## 공통 책임

- 디자인시스템 컴포넌트는 팀원 모두가 제작합니다.
- 기존 AppColor, AppFont, AppSpacing, AppRadius와 공통 UI를 먼저 사용합니다.
- 새 공통 컴포넌트를 만들거나 변경할 때는 사용 방법과 영향을 받는 화면을 공유합니다.

## UI 개발

- Figma에서 구현할 프레임의 링크를 복사해 구현을 요청합니다. 세부 절차는 [AGENTS.md](../AGENTS.md)를 따릅니다.
- 화면은 `Presentation/<Feature>`에 View와 Reducer로 구성합니다. State와 Action은 Reducer 내부에 정의합니다.
- 주입받은 Repository가 반환하는 Entity를 화면 상태에 반영합니다.
- 필요한 Entity 필드·타입을 서버 연결 담당에게 전달합니다.
- 서버 응답 DTO 해석과 Mapper 구현은 서버 연결 담당이 맡습니다.

## 서버 연결·테스트·기타 작업

- `Data/<Feature>`의 Endpoint, DTO, Mapper, Repository를 온전히 담당합니다.
- `Entity/<Feature>`에 UI에서 사용할 모델을 올바르게 구성합니다.
- 실제 서버 응답을 DTO로 받고 Mapper를 통해 Entity로 변환해 전달합니다.
- AppContainer에서 Repository를 생성하고 UI에 연결할 수 있도록 준비합니다.
- 서버 응답, 매핑 결과, 화면 연결을 테스트하고 정상·빈 결과·오류 상황을 확인합니다.
- 실행·설정 문제와 기타 필요한 작업을 처리합니다.

## 작업 연결

1. UI 담당이 Figma 디자인과 필요한 화면 데이터를 확인해 서버 연결 담당에게 전달합니다.
2. 서버 연결 담당이 Entity와 Repository 인터페이스를 공유하고 Data layer를 구현합니다.
3. UI 담당이 Entity를 화면에 연결하고, 서버 연결 담당이 전체 연동을 테스트합니다.

구현 구조는 [아키텍처 가이드](CleanArchitecture.md), 서버 계약과 전달 항목은 [서버 연결 가이드](APICollaboration.md)를 따릅니다.
