# Hackathon Development Priorities

This project is optimized for a one-day MVP demo. Build what proves the idea first.

Use the current hackathon brief for the product goal, evaluation criteria, and required screens.

## P0 / P1 / P2 Rule

- `P0`: 발표에서 반드시 보이는 핵심 플로우
- `P1`: 발표에는 도움 되지만 없어도 데모 가능한 기능
- `P2`: 있으면 좋지만 시간 남을 때만 하는 기능

예시:

- `P0`: 로그인, 메인 화면 진입, 핵심 액션 1개
- `P1`: empty / error / loading polish, 세부 문구 개선
- `P2`: 설정 화면, 고급 애니메이션, 구조 리팩터링

## Priority Order

1. Demo-critical user flow.
2. API contracts for that flow.
3. Basic loading, empty, and error states.
4. Authentication/token persistence if the flow needs it.
5. Polish for the screens that will be demoed.
6. Tests or mocks for fragile demo paths.
7. Boundary cleanup that prevents API/domain leakage.

## Default Technical Choices

- SwiftUI views plus small stores or view models under `Presentation/<FeatureName>`.
- Feature-specific endpoints under `Data/<Feature>`.
- DTOs, data sources, mappers, and repository implementations under `Data/<Domain>`.
- Entities, use cases, and repository protocols under `Domain/<Domain>` when a real API-backed feature needs them.
- Constructor injection for dependencies.
- Protocols where they define domain contracts, previews, tests, or mocks.
- Keychain for tokens and secrets.
- `UserDefaults` for non-sensitive flags and preferences.

## Avoid Unless Clearly Needed Today

- Local DB.
- Offline sync.
- Complex caching layers.
- Repository protocol/implementation pairs for endpoints that do not feed product behavior.
- Use-case/interactor layers that only pass through one network call without adding a domain boundary.
- Empty Domain/Data folder splits for placeholder product features.
- Generic request builders that hide simple API calls.
- Large refactors while UI/API work is still moving.

## Decision Test

Before adding an abstraction, ask:

- Does it help the demo flow today?
- Does it remove real duplicate code that already exists?
- Can another teammate understand it in under five minutes?
- Will it reduce merge conflicts?

If the answer is not clearly yes, keep the simpler version.

## End-of-Day Checklist

- Main demo flow works on a clean run.
- API base URL points to the demo backend.
- Tokens persist across app relaunch when auth is part of the demo.
- User-facing strings are clear, final, and kept close to the screen or view data that renders them.
- README notes any mocked endpoints or unfinished edges.
- No secrets are committed.
