import Foundation

nonisolated struct TicketAPIResponseDTO<T: Decodable & Equatable>: Decodable, Equatable {
    let code: Int
    let message: String
    let data: T?

    var success: Bool {
        code == 0 || (200..<300).contains(code)
    }
}

nonisolated struct TicketVoidResponseDTO: Decodable, Equatable, Sendable {
    init() {}

    init(from decoder: Decoder) throws {
        self.init()
    }
}

nonisolated struct TicketCreateRequestDTO: Encodable, Equatable, Sendable {
    let movieSeq: Int64
    let watchedDate: String
    let watchedTime: String
    let rating: Int
    let review: String?
}

nonisolated struct TicketCreateResponseDTO: Decodable, Equatable, Sendable {
    let ticketID: Int64?

    private enum CodingKeys: String, CodingKey {
        case id
        case ticketId
        case ticketID
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer() {
            if let id = try? container.decode(Int64.self) {
                ticketID = id
                return
            }
            if let rawValue = try? container.decode(String.self) {
                ticketID = Int64(rawValue.trimmingCharacters(in: .whitespacesAndNewlines))
                return
            }
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        ticketID = try container.decodeIfPresent(Int64.self, forKey: .id)
            ?? container.decodeIfPresent(Int64.self, forKey: .ticketId)
            ?? container.decodeIfPresent(Int64.self, forKey: .ticketID)
    }
}

nonisolated struct TicketUpdateRequestDTO: Encodable, Equatable, Sendable {
    let watchedDate: String?
    let watchedTime: String?
    let rating: Int?
    let review: String?
}

nonisolated struct TicketResponseDTO: Decodable, Equatable, Sendable {
    let id: Int64
    let movieSeq: Int64
    let watchedDate: String
    let watchedTime: String
    let rating: Int
    let review: String
    let showYn: Bool
    let createdAt: String
    let updatedAt: String
    let likeCount: Int?
    let isLiked: Bool?
    let movieTitle: String?
    let movieGenre: String?
    let movieDirector: String?
    let movieReleaseYear: String?
    let movieRunningTime: String?
    let movieImagePath: String?
    let moviePosterURLString: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case movieSeq
        case movie
        case watchedDate
        case watchedTime
        case rating
        case review
        case showYn
        case createdAt
        case updatedAt
        case likeCount
        case likesCount
        case likeCnt
        case likes
        case isLiked
        case liked
        case likedByMe
        case title
        case movieTitle
        case korTitle
        case engTitle
        case genre
        case genreName
        case movieGenre
        case director
        case movieDirector
        case productionYear
        case releaseYear
        case movieReleaseYear
        case duration
        case runningTime
        case movieRunningTime
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
        let movie = try? container.decodeIfPresent(TicketMovieResponseDTO.self, forKey: .movie)

        id = try container.decode(Int64.self, forKey: .id)
        movieSeq = try container.decode(Int64.self, forKey: .movieSeq)
        watchedDate = try container.decode(String.self, forKey: .watchedDate)
        watchedTime = try container.decode(String.self, forKey: .watchedTime)
        rating = try container.decode(Int.self, forKey: .rating)
        review = try container.decode(String.self, forKey: .review)
        showYn = try container.decode(Bool.self, forKey: .showYn)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount)
            ?? container.decodeIfPresent(Int.self, forKey: .likesCount)
            ?? container.decodeIfPresent(Int.self, forKey: .likeCnt)
            ?? container.decodeIfPresent(Int.self, forKey: .likes)
        isLiked = Self.decodeBoolIfPresent(container, keys: [.liked, .isLiked, .likedByMe])
        movieTitle = Self.firstNonEmpty(
            movie?.displayTitle,
            Self.decodeStringIfPresent(container, keys: [.movieTitle, .title, .korTitle, .engTitle])
        )
        movieGenre = Self.firstNonEmpty(
            movie?.genreName,
            Self.decodeStringIfPresent(container, keys: [.movieGenre, .genreName, .genre])
        )
        movieDirector = Self.firstNonEmpty(
            movie?.director,
            Self.decodeStringIfPresent(container, keys: [.movieDirector, .director])
        )
        movieReleaseYear = Self.firstNonEmpty(
            movie?.productionYear,
            Self.decodeStringIfPresent(container, keys: [.movieReleaseYear, .productionYear, .releaseYear])
        )
        movieRunningTime = Self.firstNonEmpty(
            movie?.runningTime,
            Self.decodeStringIfPresent(container, keys: [.movieRunningTime, .runningTime, .duration])
        )
        movieImagePath = Self.firstNonEmpty(
            movie?.imagePath,
            Self.decodeStringIfPresent(container, keys: [.movieImagePath, .imagePath])
        )
        moviePosterURLString = Self.firstNonEmpty(
            movie?.posterURLString,
            Self.decodeStringIfPresent(container, keys: [.moviePosterURL, .moviePosterUrl, .posterImageURL, .posterImageUrl, .posterURL, .posterUrl])
        )
    }

    private static func decodeStringIfPresent(
        _ container: KeyedDecodingContainer<CodingKeys>,
        keys: [CodingKeys]
    ) -> String? {
        for key in keys {
            if let value = try? container.decodeIfPresent(String.self, forKey: key),
               let normalized = nonEmpty(value) {
                return normalized
            }
            if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
                return String(value)
            }
        }
        return nil
    }

    private static func decodeBoolIfPresent(
        _ container: KeyedDecodingContainer<CodingKeys>,
        keys: [CodingKeys]
    ) -> Bool? {
        for key in keys {
            if let value = try? container.decodeIfPresent(Bool.self, forKey: key) {
                return value
            }
            if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
                return value != 0
            }
            if let value = try? container.decodeIfPresent(String.self, forKey: key) {
                switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
                case "true", "1", "yes", "y":
                    return true
                case "false", "0", "no", "n":
                    return false
                default:
                    continue
                }
            }
        }
        return nil
    }

    private static func firstNonEmpty(_ values: String?...) -> String? {
        values.compactMap(nonEmpty).first
    }

    private static func nonEmpty(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }
}

nonisolated private struct TicketMovieResponseDTO: Decodable, Equatable, Sendable {
    let korTitle: String?
    let engTitle: String?
    let title: String?
    let genreName: String?
    let director: String?
    let productionYear: String?
    let runningTime: String?
    let imagePath: String?
    let posterURLString: String?

    private enum CodingKeys: String, CodingKey {
        case korTitle
        case engTitle
        case title
        case genreName
        case genre
        case director
        case productionYear
        case releaseYear
        case duration
        case runningTime
        case imagePath
        case posterImageURL
        case posterImageUrl
        case posterURL
        case posterUrl
    }

    nonisolated var displayTitle: String? {
        firstNonEmpty(korTitle, title, engTitle)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        korTitle = Self.decodeStringIfPresent(container, keys: [.korTitle])
        engTitle = Self.decodeStringIfPresent(container, keys: [.engTitle])
        title = Self.decodeStringIfPresent(container, keys: [.title])
        genreName = Self.decodeStringIfPresent(container, keys: [.genreName, .genre])
        director = Self.decodeStringIfPresent(container, keys: [.director])
        productionYear = Self.decodeStringIfPresent(container, keys: [.productionYear, .releaseYear])
        runningTime = Self.decodeStringIfPresent(container, keys: [.runningTime, .duration])
        imagePath = Self.decodeStringIfPresent(container, keys: [.imagePath])
        posterURLString = Self.decodeStringIfPresent(container, keys: [.posterImageURL, .posterImageUrl, .posterURL, .posterUrl])
    }

    nonisolated private func firstNonEmpty(_ values: String?...) -> String? {
        values.compactMap(Self.nonEmpty).first
    }

    nonisolated private static func decodeStringIfPresent(
        _ container: KeyedDecodingContainer<CodingKeys>,
        keys: [CodingKeys]
    ) -> String? {
        for key in keys {
            if let value = try? container.decodeIfPresent(String.self, forKey: key),
               let normalized = nonEmpty(value) {
                return normalized
            }
            if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
                return String(value)
            }
        }
        return nil
    }

    nonisolated private static func nonEmpty(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }
}

typealias PublicTicketListResponseDTO = TicketAPIResponseDTO<[TicketResponseDTO]>
