# Authentication Integration

The starter opens directly into two sample tabs. Add an authentication screen when the new product requires one.

- Adapt `Data/Auth` and `Data/User` to the new API contract and inject the relevant repository from `AppContainer`.
- `AuthRepository` stores an access token through `TokenStoring`. The default `KeychainTokenStore` scopes the item to the app bundle identifier.
- `AuthInterceptor` attaches the bearer token to endpoints that require authentication. Inject an `AccessTokenRefreshing` implementation if the server supports refresh.
- The interceptor clears the token and posts `authSessionExpired` when session refresh fails. The app root can observe that event to route to login.
