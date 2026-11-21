import Foundation

protocol MovieRepositoryProtocol {
    var hasAccessToken: Bool { get }
    func fetchMovies(pageRequest: MoviePageRequest) async throws(NetworkError) -> MoviePage
    func fetchRecordMovies(keyword: String, page: Int, size: Int) async throws(NetworkError) -> RecordMoviePage
    func fetchMovie(seq: Int64) async throws(NetworkError) -> MovieDetail
    func signOut()
}

final class MovieRepository: MovieRepositoryProtocol {
    private let networkManager: NetworkManager
    private let tokenStore: TokenStoring
    private let recordMovieCache = RecordMovieCache()
    private let movieDetailCache = MovieDetailCache()

    init(networkManager: NetworkManager, tokenStore: TokenStoring) {
        self.networkManager = networkManager
        self.tokenStore = tokenStore
    }

    var hasAccessToken: Bool {
        tokenStore.accessToken?.isEmpty == false
    }

    func fetchMovies(pageRequest: MoviePageRequest) async throws(NetworkError) -> MoviePage {
        let response = try await networkManager.request(
            MovieEndpoint.list(pageRequest),
            as: MovieAPIResponseDTO<MoviePageResponseDTO>.self
        )

        guard response.success, let data = response.data else {
            throw movieError(response, fallbackCode: "MOVIE_LIST_FAILED")
        }

        return MovieMapper.map(data)
    }

    func fetchRecordMovies(keyword: String, page: Int, size: Int) async throws(NetworkError) -> RecordMoviePage {
        let normalizedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        let cacheKey = RecordMovieCache.PageKey(keyword: normalizedKeyword, page: page, size: size)

        if let cachedPage = await recordMovieCache.page(for: cacheKey) {
            return cachedPage
        }

        let moviePage = try await fetchMovies(pageRequest: MoviePageRequest(
            keyword: normalizedKeyword,
            page: page,
            size: size
        ))
        let recordMoviePage = RecordMovieMapper.map(moviePage)
        await recordMovieCache.store(recordMoviePage, for: cacheKey)

        return recordMoviePage
    }

    func fetchMovie(seq: Int64) async throws(NetworkError) -> MovieDetail {
        if let cachedMovie = await movieDetailCache.movie(for: seq) {
            return cachedMovie
        }

        do {
            let response = try await networkManager.request(
                MovieEndpoint.detail(seq: seq),
                as: MovieAPIResponseDTO<MovieDetailResponseDTO>.self
            )

            guard response.success, let data = response.data else {
                throw movieError(response, fallbackCode: "MOVIE_DETAIL_FAILED")
            }

            let movie = MovieMapper.map(data)
            await movieDetailCache.store(movie)
            return movie
        } catch {
            let networkError = error as? NetworkError ?? .unknown(errorCode: error.localizedDescription)
            if let cachedRecordMovie = await recordMovieCache.movie(for: seq) {
                let movie = MovieMapper.map(cachedRecordMovie)
                await movieDetailCache.store(movie)
                AppLogger.warning("Movie detail fallback from record cache: seq=\(seq) error=\(networkError)")
                return movie
            }
            throw networkError
        }
    }

    func signOut() {
        tokenStore.clear()
    }

    private func movieError<T: Decodable & Equatable>(
        _ response: MovieAPIResponseDTO<T>,
        fallbackCode: String
    ) -> NetworkError {
        if response.message.isEmpty == false {
            return .apiError(code: String(response.code), message: response.message)
        }
        return .unknown(errorCode: fallbackCode)
    }
}

private actor RecordMovieCache {
    struct PageKey: Hashable, Sendable {
        let keyword: String
        let page: Int
        let size: Int
    }

    private let maxPageCacheCount = 8
    private let maxMovieCacheCount = 200
    private var pages: [PageKey: RecordMoviePage] = [:]
    private var pageOrder: [PageKey] = []
    private var moviesBySeq: [Int64: RecordMovie] = [:]
    private var movieOrder: [Int64] = []

    func page(for key: PageKey) -> RecordMoviePage? {
        pages[key]
    }

    func movie(for seq: Int64) -> RecordMovie? {
        moviesBySeq[seq]
    }

    func store(_ page: RecordMoviePage, for key: PageKey) {
        if pages[key] == nil {
            pageOrder.append(key)
        }
        pages[key] = page
        page.movies.forEach(storeMovie)
        trimPageCacheIfNeeded()
        trimMovieCacheIfNeeded()
    }

    private func trimPageCacheIfNeeded() {
        while pageOrder.count > maxPageCacheCount {
            let oldestKey = pageOrder.removeFirst()
            pages.removeValue(forKey: oldestKey)
        }
    }

    private func storeMovie(_ movie: RecordMovie) {
        if moviesBySeq[movie.seq] == nil {
            movieOrder.append(movie.seq)
        }
        moviesBySeq[movie.seq] = movie
    }

    private func trimMovieCacheIfNeeded() {
        while movieOrder.count > maxMovieCacheCount {
            let oldestSeq = movieOrder.removeFirst()
            moviesBySeq.removeValue(forKey: oldestSeq)
        }
    }
}

private actor MovieDetailCache {
    private let maxCacheCount = 200
    private var moviesBySeq: [Int64: MovieDetail] = [:]
    private var movieOrder: [Int64] = []

    func movie(for seq: Int64) -> MovieDetail? {
        moviesBySeq[seq]
    }

    func store(_ movie: MovieDetail) {
        guard movie.seq != 0 else { return }

        if moviesBySeq[movie.seq] == nil {
            movieOrder.append(movie.seq)
        }
        moviesBySeq[movie.seq] = movie
        trimCacheIfNeeded()
    }

    private func trimCacheIfNeeded() {
        while movieOrder.count > maxCacheCount {
            let oldestSeq = movieOrder.removeFirst()
            moviesBySeq.removeValue(forKey: oldestSeq)
        }
    }
}
