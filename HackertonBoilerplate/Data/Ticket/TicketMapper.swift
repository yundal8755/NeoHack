import Foundation

enum TicketMapper {
    nonisolated static func map(_ dto: TicketResponseDTO) -> Ticket {
        Ticket(
            id: dto.id,
            movieSeq: dto.movieSeq,
            watchedDate: dto.watchedDate,
            watchedTime: dto.watchedTime,
            rating: dto.rating,
            review: dto.review,
            showYn: dto.showYn,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            likeCount: clampedLikeCount(dto.likeCount),
            isLiked: dto.isLiked ?? false,
            movieTitle: dto.movieTitle,
            movieGenre: dto.movieGenre,
            movieDirector: dto.movieDirector,
            movieReleaseYear: dto.movieReleaseYear,
            movieRunningTime: normalizedRunningTime(dto.movieRunningTime),
            posterImageURLString: posterImageURLString(from: dto)
        )
    }

    nonisolated static func enrich(_ ticket: Ticket, with movie: MovieDetail) -> Ticket {
        Ticket(
            id: ticket.id,
            movieSeq: ticket.movieSeq,
            watchedDate: ticket.watchedDate,
            watchedTime: ticket.watchedTime,
            rating: ticket.rating,
            review: ticket.review,
            showYn: ticket.showYn,
            createdAt: ticket.createdAt,
            updatedAt: ticket.updatedAt,
            likeCount: ticket.likeCount,
            isLiked: ticket.isLiked,
            movieTitle: firstNonEmpty(movie.korTitle, movie.engTitle, ticket.movieTitle),
            movieGenre: firstNonEmpty(movie.genreName, ticket.movieGenre),
            movieDirector: firstNonEmpty(movie.director, ticket.movieDirector),
            movieReleaseYear: firstNonEmpty(movie.productionYear, ticket.movieReleaseYear),
            movieRunningTime: normalizedRunningTime(firstNonEmpty(movie.duration, ticket.movieRunningTime)),
            posterImageURLString: movie.posterImageURLString
                ?? MovieEndpoint.imageURLString(imagePath: movie.imagePath)
                ?? ticket.posterImageURLString
        )
    }

    nonisolated static func enrich(_ tickets: [Ticket], with moviesBySeq: [Int64: MovieDetail]) -> [Ticket] {
        tickets.map { ticket in
            guard let movie = moviesBySeq[ticket.movieSeq] else { return ticket }
            return enrich(ticket, with: movie)
        }
    }

    nonisolated static func enrich(_ ticket: PublicTicket, with movie: MovieDetail) -> PublicTicket {
        PublicTicket(
            id: ticket.id,
            movieSeq: ticket.movieSeq,
            watchedDate: ticket.watchedDate,
            watchedTime: ticket.watchedTime,
            rating: ticket.rating,
            review: ticket.review,
            showYn: ticket.showYn,
            createdAt: ticket.createdAt,
            updatedAt: ticket.updatedAt,
            likeCount: ticket.likeCount,
            isLiked: ticket.isLiked,
            movieTitle: firstNonEmpty(movie.korTitle, movie.engTitle, ticket.movieTitle),
            movieGenre: firstNonEmpty(movie.genreName, ticket.movieGenre),
            movieDirector: firstNonEmpty(movie.director, ticket.movieDirector),
            movieReleaseYear: firstNonEmpty(movie.productionYear, ticket.movieReleaseYear),
            movieRunningTime: normalizedRunningTime(firstNonEmpty(movie.duration, ticket.movieRunningTime)),
            posterImageURLString: movie.posterImageURLString
                ?? MovieEndpoint.imageURLString(imagePath: movie.imagePath)
                ?? ticket.posterImageURLString
        )
    }

    nonisolated static func enrich(_ tickets: [PublicTicket], with moviesBySeq: [Int64: MovieDetail]) -> [PublicTicket] {
        tickets.map { ticket in
            guard let movie = moviesBySeq[ticket.movieSeq] else { return ticket }
            return enrich(ticket, with: movie)
        }
    }

    nonisolated static func mapPublicTickets(_ dtos: [TicketResponseDTO]) -> PublicTicketPage {
        PublicTicketPage(
            tickets: dtos.map(mapPublicTicket),
            page: 0,
            hasNextPage: false
        )
    }

    private nonisolated static func mapPublicTicket(_ dto: TicketResponseDTO) -> PublicTicket {
        PublicTicket(
            id: dto.id,
            movieSeq: dto.movieSeq,
            watchedDate: dto.watchedDate,
            watchedTime: dto.watchedTime,
            rating: dto.rating,
            review: dto.review,
            showYn: dto.showYn,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            likeCount: clampedLikeCount(dto.likeCount),
            isLiked: dto.isLiked ?? false,
            movieTitle: dto.movieTitle,
            movieGenre: dto.movieGenre,
            movieDirector: dto.movieDirector,
            movieReleaseYear: dto.movieReleaseYear,
            movieRunningTime: normalizedRunningTime(dto.movieRunningTime),
            posterImageURLString: posterImageURLString(from: dto)
        )
    }

    private nonisolated static func clampedLikeCount(_ count: Int?) -> Int {
        min(max(count ?? 0, 0), 9_999)
    }

    private nonisolated static func firstNonEmpty(_ values: String?...) -> String? {
        values.compactMap(nonEmpty).first
    }

    private nonisolated static func posterImageURLString(from dto: TicketResponseDTO) -> String? {
        if let posterURLString = nonEmpty(dto.moviePosterURLString) {
            return posterURLString
        }

        guard let imagePath = nonEmpty(dto.movieImagePath) else { return nil }
        return MovieEndpoint.imageURLString(imagePath: imagePath)
    }

    private nonisolated static func normalizedRunningTime(_ rawValue: String?) -> String? {
        guard let value = nonEmpty(rawValue) else { return nil }
        if value.hasSuffix("분") { return value }
        return Int(value).map { "\($0)분" } ?? value
    }

    private nonisolated static func nonEmpty(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }
}
