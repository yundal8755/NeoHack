import Foundation

enum RecordMovieMapper {
    static func map(_ page: MoviePage) -> RecordMoviePage {
        RecordMoviePage(
            movies: page.content.map(map),
            page: page.number,
            hasNextPage: !page.last
        )
    }

    private static func map(_ movie: MovieListItem) -> RecordMovie {
        RecordMovie(
            id: String(movie.seq),
            seq: movie.seq,
            title: movie.korTitle.isEmpty ? movie.engTitle : movie.korTitle,
            genre: movie.genreName,
            director: movie.director,
            releaseYear: Int(movie.productionYear),
            runningTimeMinutes: nil,
            averageRating: nil,
            reviewCount: nil,
            posterImageURLString: MovieEndpoint.imageURLString(imagePath: movie.imagePath)
        )
    }

    static func merging(_ detail: MovieDetail, into movie: RecordMovie) -> RecordMovie {
        guard let minutes = parseRunningMinutes(from: detail.duration) else { return movie }
        return RecordMovie(
            id: movie.id,
            seq: movie.seq,
            title: movie.title,
            genre: movie.genre,
            director: movie.director,
            releaseYear: movie.releaseYear,
            runningTimeMinutes: minutes,
            averageRating: movie.averageRating,
            reviewCount: movie.reviewCount,
            posterImageURLString: movie.posterImageURLString
        )
    }

    private static func parseRunningMinutes(from raw: String) -> Int? {
        let digits = raw.trimmingCharacters(in: .whitespaces).prefix { $0.isNumber }
        return Int(digits)
    }
}
