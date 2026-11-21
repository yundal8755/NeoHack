# Clean Architecture Guide

This project follows Clean Architecture boundaries while keeping SwiftUI feature work practical. The folder name `Domain` means app business domain, and `Data/<Feature>` contains the backend API domain that owns endpoint routing and DTO mapping.

## Required Layer Boundaries

```text
Presentation -> Data -> Core/Network
```

- `Presentation` can import SwiftUI and render state. It can call use cases, stores, or view models, but it must not build URLs or decode API DTOs.
- `Domain` contains pure Swift entities, use cases, and repository protocols. It must not import SwiftUI, Alamofire, or network routers.
- `Data` contains Feature-specific endpoints, DTOs, mappers, and repository implementations. It can depend on `Core/Network` and `Domain`.
- `Core/Network` contains HTTP infrastructure. It should not know about domain entities or SwiftUI state.
- `App` is the composition root and may wire concrete implementations across layers.

## API Domain Endpoint Convention

Backend API domains determine endpoint placement:

```text
API domain: Auth      -> Data/Auth/AuthEndpoint.swift
API domain: Server    -> Core/Network/Server/ServerAPI.swift
API domain: User      -> Data/User/UserEndpoint.swift
API domain: Orders    -> Data/Orders/OrdersEndpoint.swift
```

Endpoint rules:

- One `Data` folder per API domain.
- Endpoint cases match endpoint intent, not screen names.
- Endpoints conform to `TargetType`.
- Endpoints own method, path, query parameters, body, headers, and auth requirement.
- Endpoints do not decode responses, map DTOs, own tokens, or update UI state.
- Provider-specific endpoint names are not allowed in shared roots. Use product domain names from the API contract instead.

## Data Layer Convention

Use this structure when an API domain starts feeding product behavior in the MVP layer:

```text
Data/<Domain>/<Domain>DTO.swift
Data/<Domain>/<Domain>Endpoint.swift
Data/<Domain>/<Domain>Mapper.swift
Data/<Domain>/<Domain>Repository.swift
```

- DTOs mirror API payloads and can use server field naming via `CodingKeys`.
- Repositories call `NetworkManager` with the matching `Data/<Feature>` endpoint.
- Mappers convert DTOs into feature/domain-friendly models.
- Introduce `Domain` repository protocols only when the feature needs a stable business boundary.

## Domain Layer Convention

Use this structure for app-facing business behavior:

```text
Domain/<Domain>/Entities/
Domain/<Domain>/Repositories/
Domain/<Domain>/UseCases/
```

- Entities are stable app models, not raw response DTOs.
- Repository protocols describe what the app needs, not every endpoint the server exposes.
- Use cases represent user/business actions and coordinate repository calls.
- Do not add use cases just to pass through a single field unless the feature needs the boundary for testing or reuse.

## Presentation Convention

Use `Presentation/<Feature>` for SwiftUI surfaces:

```text
Presentation/<Feature>/<Feature>View.swift
Presentation/<Feature>/<Feature>ViewModel.swift
Presentation/<Feature>/<Feature>Store.swift
Presentation/<Feature>/<Feature>State.swift
Presentation/<Feature>/<Feature>Intent.swift
```

- MVVM is acceptable for straightforward screens.
- MVI is acceptable for screens with complex state transitions.
- Views should render state and forward user actions.
- Stores/view models should call use cases or injected repositories, not routers.
- Navigation routes live in `App/Navigation` and should reference app concepts, not backend endpoint names.

## Composition Root

`App/AppContainer.swift` wires concrete dependencies:

- Token storage and network infrastructure.
- Network services and data sources.
- Repository implementations for domain protocols.
- Use cases consumed by features.

Do not instantiate concrete routers, network managers, or repository implementations directly inside SwiftUI views.

## Checklist Before Adding A Feature

- The API domain is known.
- The endpoint is under `Data/<Feature>`.
- DTOs are under `Data/<Domain>/DTO`.
- Domain entities are free of transport-specific names.
- Repository protocols live in `Domain`, implementations live in `Data`.
- The feature imports presentation/domain concepts, not provider-specific routers.
- Any temporary mock or placeholder is named as such and does not introduce a fake product domain.
