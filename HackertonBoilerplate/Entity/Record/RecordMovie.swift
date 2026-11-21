import Foundation

struct RecordMoviePage: Equatable, Sendable {
    let movies: [RecordMovie]
    let page: Int
    let hasNextPage: Bool
}

struct RecordMovie: Identifiable, Equatable, Sendable {
    let id: String
    let seq: Int64
    let title: String
    let genre: String
    let director: String
    let releaseYear: Int?
    let runningTimeMinutes: Int?
    let averageRating: Double?
    let reviewCount: Int?
    let posterImageURLString: String?

    var metadataText: String {
        [genre, directorText, releaseYearText, runningTimeText]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    var ratingText: String {
        guard let averageRating else { return "평점 없음" }
        return String(format: "%.1f", averageRating)
    }

    var reviewCountText: String? {
        guard let reviewCount else { return nil }
        return "(\(reviewCount))"
    }

    private var directorText: String? {
        guard director.isEmpty == false else { return nil }
        return "\(director) 감독"
    }

    private var releaseYearText: String? {
        guard let releaseYear else { return nil }
        return "\(releaseYear)년"
    }

    private var runningTimeText: String? {
        guard let runningTimeMinutes else { return nil }
        return "\(runningTimeMinutes)분"
    }
}
