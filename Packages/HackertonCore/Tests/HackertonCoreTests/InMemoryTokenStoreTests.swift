import HackertonCore
import HackertonMocks
import Testing

@Suite("InMemoryTokenStore")
struct InMemoryTokenStoreTests {
    @Test func 저장한_토큰을_읽고_clear하면_비운다() {
        var store: any TokenStoring = InMemoryTokenStore()
        #expect(store.accessToken == nil)

        store.accessToken = "token"
        #expect(store.accessToken == "token")

        store.clear()
        #expect(store.accessToken == nil)
    }
}
