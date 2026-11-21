# iOS Developer Handoff

- Start with [README](../README.md) for simulator setup and [AGENTS.md](../AGENTS.md) for the Figma workflow.
- `App` holds the app entry point, starter tabs, shared tokens, and `AppContainer`. Put new screens under `Presentation/<Feature>`. Stateful screens use the shared MVI core with a View and Reducer.
- `Core/Network` handles requests, decoding, and authentication. `Data/<Feature>` contains DTOs, endpoints, mappers, and repositories. `Entity` holds shared models.
- Agree on the API contract before wiring the live repository. Use sample data when building UI before the server is ready.
- Build on a simulator and exercise the affected flow before sharing a change. Keep server-specific settings in the ignored local config.

See [API Collaboration](APICollaboration.md) and [GitHub Collaboration](GitHubCollaboration.md) for team conventions.
