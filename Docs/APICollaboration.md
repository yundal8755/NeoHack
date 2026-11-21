# API Collaboration Rules

Keep the backend/frontend contract simple and explicit. The goal is to unblock screens quickly, not design a perfect public API.

## Contract First

- Write the endpoint path, method, request body, response body, and error cases before wiring UI.
- Share one sample success JSON and one sample failure JSON per endpoint.
- Keep field names stable once the iOS screen depends on them.

## What to Share for Every Endpoint

- endpoint name
- HTTP method
- request JSON
- response JSON
- error response
- mock response
- whether auth is required
- baseURL or environment value used for testing

## API Domain Shape

Document the API contract before connecting a live backend.

- Treat each API domain as an iOS network domain.
- Share new endpoints under the correct API domain before iOS adds a router case.
- iOS places endpoint definitions at `Data/<Feature>/<Feature>Endpoint.swift`.
- Do not name routers after third-party providers or temporary demo datasets.

## Endpoint Shape

- Prefer predictable REST-style paths: `GET /items`, `GET /items/{id}`, `POST /api/auth/login`.
- Use JSON request bodies for `POST`.
- Return JSON responses for both success and expected failures.
- Use ISO 8601 strings for dates.
- Use snake_case in API payloads; the app converts to Swift camelCase.

## Authentication

- Return an access token from login or signup.
- iOS stores the token in Keychain via `KeychainTokenStore`.
- iOS sends `Authorization: Bearer <token>` when a token exists.
- Return `401` when the token is missing, expired, or invalid.

## Errors

Use HTTP status codes plus a small JSON body when the server can explain the problem:

```json
{
  "message": "Email is already registered"
}
```

The app currently maps invalid URL, unauthorized, server status, decoding, network, and unknown errors. Keep custom error formats simple unless a screen needs field-level validation.

## MVP Defaults

- No local DB by default.
- No offline sync by default.
- No complex cache invalidation by default.
- Use Clean Architecture boundaries when connecting real API domains: `Core/Network` infrastructure, `Data` endpoint/DTO/mapper/repository implementation, optional `Domain` entity/use case/repository protocol, and `Presentation` UI.
- Mock only endpoints that are not ready, and mark mocked data clearly in the PR.

## Recommended API Share Format

```text
[Endpoint]
POST /api/auth/login

[Request]
{
  "login_id": "<login-id>",
  "password": "<password>"
}

[Response]
{
  "access_token": "<access-token>",
  "nickname": "Demo"
}

[Error Response]
{
  "message": "Email is already registered"
}

[Mock Response]
Same as response above, stored in a shared doc or JSON file.
```

## Base URL Rule

- Keep one shared base URL per environment.
- During a hackathon, a single demo base URL is usually enough.
- If the backend changes, notify iOS before the demo build is cut.

## Change Rules

- If a response shape changes, notify the iOS teammate before merging backend changes.
- If an endpoint is blocked, provide a static sample JSON so UI can continue.
- If the backend is unstable, iOS may temporarily point a feature service at local sample data, but the PR must say so.
