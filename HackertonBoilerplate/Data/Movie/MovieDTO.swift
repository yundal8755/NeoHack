import Foundation

nonisolated struct MovieAPIResponseDTO<T: Decodable & Equatable>: Decodable, Equatable {
    let code: Int
    let message: String
    let data: T?

    var success: Bool {
        code == 0 || (200..<300).contains(code)
    }
}

nonisolated struct MoviePageResponseDTO: Decodable, Equatable, Sendable {
    let totalElements: Int64
    let totalPages: Int
    let size: Int
    let content: [MovieListResponseDTO]
    let number: Int
    let numberOfElements: Int
    let first: Bool
    let last: Bool
    let empty: Bool
}

nonisolated struct MovieListResponseDTO: Decodable, Equatable, Sendable {
    let seq: Int64
    let korTitle: String
    let engTitle: String
    let director: String
    let productionYear: String
    let genreName: String
    let imagePath: String

    private enum CodingKeys: String, CodingKey {
        case seq
        case movieSeq
        case id
        case korTitle
        case koreanTitle
        case title
        case movieTitle
        case engTitle
        case englishTitle
        case director
        case productionYear
        case releaseYear
        case genreName
        case genre
        case imagePath
        case movieImagePath
        case posterImageURL
        case posterImageUrl
        case posterURL
        case posterUrl
        case moviePosterURL
        case moviePosterUrl
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        seq = MovieDTOValueDecoder.int64(container, keys: [.seq, .movieSeq, .id]) ?? 0
        korTitle = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(container, keys: [.korTitle, .koreanTitle, .movieTitle, .title])
        ) ?? ""
        engTitle = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(container, keys: [.engTitle, .englishTitle])
        ) ?? ""
        director = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(container, keys: [.director])
        ) ?? ""
        productionYear = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(container, keys: [.productionYear, .releaseYear])
        ) ?? ""
        genreName = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(container, keys: [.genreName, .genre])
        ) ?? ""
        imagePath = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(
                container,
                keys: [
                    .imagePath,
                    .movieImagePath,
                    .moviePosterURL,
                    .moviePosterUrl,
                    .posterImageURL,
                    .posterImageUrl,
                    .posterURL,
                    .posterUrl
                ]
            )
        ) ?? ""
    }
}

nonisolated struct MovieDetailResponseDTO: Decodable, Equatable, Sendable {
    let seq: Int64
    let korTitle: String
    let engTitle: String
    let director: String
    let actors: String
    let productionYear: String
    let genreName: String
    let companyNm: String
    let distributorNm: String
    let imagePath: String
    let duration: String
    let rating: String
    let colorType: String
    let synopsis: String
    let screenwriter: String
    let producer: String
    let releaseDate: String
    let keywords: String

    private enum CodingKeys: String, CodingKey {
        case seq
        case movieSeq
        case id
        case korTitle
        case koreanTitle
        case title
        case movieTitle
        case engTitle
        case englishTitle
        case director
        case actors
        case actor
        case cast
        case productionYear
        case releaseYear
        case genreName
        case genre
        case companyNm
        case companyName
        case distributorNm
        case distributorName
        case imagePath
        case movieImagePath
        case posterImageURL
        case posterImageUrl
        case posterURL
        case posterUrl
        case moviePosterURL
        case moviePosterUrl
        case duration
        case runningTime
        case runtime
        case rating
        case colorType
        case synopsis
        case screenwriter
        case writer
        case producer
        case releaseDate
        case keywords
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        seq = MovieDTOValueDecoder.int64(container, keys: [.seq, .movieSeq, .id]) ?? 0
        korTitle = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(container, keys: [.korTitle, .koreanTitle, .movieTitle, .title])
        ) ?? ""
        engTitle = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(container, keys: [.engTitle, .englishTitle])
        ) ?? ""
        director = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(container, keys: [.director])
        ) ?? ""
        actors = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(container, keys: [.actors, .actor, .cast])
        ) ?? ""
        productionYear = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(container, keys: [.productionYear, .releaseYear])
        ) ?? ""
        genreName = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(container, keys: [.genreName, .genre])
        ) ?? ""
        companyNm = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(container, keys: [.companyNm, .companyName])
        ) ?? ""
        distributorNm = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(container, keys: [.distributorNm, .distributorName])
        ) ?? ""
        imagePath = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(
                container,
                keys: [
                    .imagePath,
                    .movieImagePath,
                    .moviePosterURL,
                    .moviePosterUrl,
                    .posterImageURL,
                    .posterImageUrl,
                    .posterURL,
                    .posterUrl
                ]
            )
        ) ?? ""
        duration = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(container, keys: [.duration, .runningTime, .runtime])
        ) ?? ""
        rating = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(container, keys: [.rating])
        ) ?? ""
        colorType = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(container, keys: [.colorType])
        ) ?? ""
        synopsis = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(container, keys: [.synopsis])
        ) ?? ""
        screenwriter = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(container, keys: [.screenwriter, .writer])
        ) ?? ""
        producer = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(container, keys: [.producer])
        ) ?? ""
        releaseDate = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(container, keys: [.releaseDate])
        ) ?? ""
        keywords = MovieDTOValueDecoder.firstNonEmpty(
            MovieDTOValueDecoder.string(container, keys: [.keywords])
        ) ?? ""
    }
}

private enum MovieDTOValueDecoder {
    nonisolated static func int64<Key: CodingKey>(
        _ container: KeyedDecodingContainer<Key>,
        keys: [Key]
    ) -> Int64? {
        for key in keys {
            if let value = try? container.decodeIfPresent(Int64.self, forKey: key) {
                return value
            }
            if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
                return Int64(value)
            }
            if let value = try? container.decodeIfPresent(String.self, forKey: key),
               let normalized = Int64(value.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return normalized
            }
        }
        return nil
    }

    nonisolated static func string<Key: CodingKey>(
        _ container: KeyedDecodingContainer<Key>,
        keys: [Key]
    ) -> String? {
        for key in keys {
            if let value = try? container.decodeIfPresent(String.self, forKey: key),
               let normalized = nonEmpty(value) {
                return normalized
            }
            if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
                return String(value)
            }
            if let value = try? container.decodeIfPresent(Int64.self, forKey: key) {
                return String(value)
            }
            if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
                return String(value)
            }
            if let values = try? container.decodeIfPresent([String].self, forKey: key) {
                let joined = values
                    .compactMap(nonEmpty)
                    .joined(separator: ", ")
                if joined.isEmpty == false {
                    return joined
                }
            }
        }
        return nil
    }

    nonisolated static func firstNonEmpty(_ values: String?...) -> String? {
        values.compactMap(nonEmpty).first
    }

    nonisolated private static func nonEmpty(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }
}
