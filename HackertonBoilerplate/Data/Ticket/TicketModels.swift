import Foundation

nonisolated struct TicketCreate: Equatable, Sendable {
    let movieSeq: Int64
    let watchedDate: String
    let watchedTime: String
    let rating: Int
    let review: String?
}

nonisolated struct TicketUpdate: Equatable, Sendable {
    let watchedDate: String?
    let watchedTime: String?
    let rating: Int?
    let review: String?
}

nonisolated struct Ticket: Equatable, Sendable {
    let id: Int64
    let movieSeq: Int64
    let watchedDate: String
    let watchedTime: String
    let rating: Int
    let review: String
    let showYn: Bool
    let createdAt: String
    let updatedAt: String
    let likeCount: Int
    let isLiked: Bool
    let movieTitle: String?
    let movieGenre: String?
    let movieDirector: String?
    let movieReleaseYear: String?
    let movieRunningTime: String?
    let posterImageURLString: String?

    init(
        id: Int64,
        movieSeq: Int64,
        watchedDate: String,
        watchedTime: String,
        rating: Int,
        review: String,
        showYn: Bool,
        createdAt: String,
        updatedAt: String,
        likeCount: Int = 0,
        isLiked: Bool = false,
        movieTitle: String? = nil,
        movieGenre: String? = nil,
        movieDirector: String? = nil,
        movieReleaseYear: String? = nil,
        movieRunningTime: String? = nil,
        posterImageURLString: String? = nil
    ) {
        self.id = id
        self.movieSeq = movieSeq
        self.watchedDate = watchedDate
        self.watchedTime = watchedTime
        self.rating = rating
        self.review = review
        self.showYn = showYn
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.likeCount = likeCount
        self.isLiked = isLiked
        self.movieTitle = movieTitle
        self.movieGenre = movieGenre
        self.movieDirector = movieDirector
        self.movieReleaseYear = movieReleaseYear
        self.movieRunningTime = movieRunningTime
        self.posterImageURLString = posterImageURLString
    }
}
