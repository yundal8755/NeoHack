import Foundation

protocol TicketRepositoryProtocol {
    var hasAccessToken: Bool { get }
    func fetchTickets() async throws(NetworkError) -> [Ticket]
    func fetchPublicTickets(sort: String) async throws(NetworkError) -> PublicTicketPage
    func createTicket(_ ticket: TicketCreate) async throws(NetworkError) -> Int64
    func fetchTicket(ticketId: Int64) async throws(NetworkError) -> Ticket
    func updateTicket(ticketId: Int64, update: TicketUpdate) async throws(NetworkError)
    func deleteTicket(ticketId: Int64) async throws(NetworkError)
    func shareTicket(ticketId: Int64, showYn: Bool) async throws(NetworkError)
    func signOut()
}

final class TicketRepository: TicketRepositoryProtocol {
    private let networkManager: NetworkManager
    private let tokenStore: TokenStoring

    init(networkManager: NetworkManager, tokenStore: TokenStoring) {
        self.networkManager = networkManager
        self.tokenStore = tokenStore
    }

    var hasAccessToken: Bool {
        tokenStore.accessToken?.isEmpty == false
    }

    func fetchTickets() async throws(NetworkError) -> [Ticket] {
        let response = try await networkManager.request(
            TicketEndpoint.list,
            as: TicketAPIResponseDTO<[TicketResponseDTO]>.self
        )

        guard response.success, let data = response.data else {
            throw ticketError(response, fallbackCode: "TICKET_LIST_FAILED")
        }

        return data.map(TicketMapper.map)
    }

    func fetchPublicTickets(sort: String = "latest") async throws(NetworkError) -> PublicTicketPage {
        let response = try await networkManager.request(
            TicketEndpoint.publicList(sort: sort),
            as: PublicTicketListResponseDTO.self
        )

        guard response.success, let data = response.data else {
            throw ticketError(response, fallbackCode: "PUBLIC_TICKET_LIST_FAILED")
        }

        return TicketMapper.mapPublicTickets(data)
    }

    func createTicket(_ ticket: TicketCreate) async throws(NetworkError) -> Int64 {
        let request = TicketCreateRequestDTO(
            movieSeq: ticket.movieSeq,
            watchedDate: ticket.watchedDate,
            watchedTime: ticket.watchedTime,
            rating: ticket.rating,
            review: ticket.review
        )
        let response = try await networkManager.request(
            TicketEndpoint.create(request),
            as: TicketAPIResponseDTO<TicketCreateResponseDTO>.self
        )

        guard response.success else {
            throw ticketError(response, fallbackCode: "TICKET_CREATE_FAILED")
        }

        if let ticketID = response.data?.ticketID {
            return ticketID
        }

        if let ticketID = try await findCreatedTicketID(for: ticket) {
            return ticketID
        }

        throw .unknown(errorCode: "TICKET_ID_MISSING")
    }

    func fetchTicket(ticketId: Int64) async throws(NetworkError) -> Ticket {
        let response = try await networkManager.request(
            TicketEndpoint.detail(ticketId: ticketId),
            as: TicketAPIResponseDTO<TicketResponseDTO>.self
        )

        guard response.success, let data = response.data else {
            throw ticketError(response, fallbackCode: "TICKET_DETAIL_FAILED")
        }

        return TicketMapper.map(data)
    }

    func updateTicket(ticketId: Int64, update: TicketUpdate) async throws(NetworkError) {
        let request = TicketUpdateRequestDTO(
            watchedDate: update.watchedDate,
            watchedTime: update.watchedTime,
            rating: update.rating,
            review: update.review
        )
        try await requestVoid(TicketEndpoint.update(ticketId: ticketId, request: request), failureCode: "TICKET_UPDATE_FAILED")
    }

    func deleteTicket(ticketId: Int64) async throws(NetworkError) {
        try await requestVoid(TicketEndpoint.delete(ticketId: ticketId), failureCode: "TICKET_DELETE_FAILED")
    }

    func shareTicket(ticketId: Int64, showYn: Bool) async throws(NetworkError) {
        try await requestVoid(
            TicketEndpoint.share(ticketId: ticketId, showYn: showYn),
            failureCode: "TICKET_SHARE_FAILED"
        )
    }

    func signOut() {
        tokenStore.clear()
    }

    private func requestVoid(_ endpoint: TicketEndpoint, failureCode: String) async throws(NetworkError) {
        let response = try await networkManager.request(
            endpoint,
            as: TicketAPIResponseDTO<TicketVoidResponseDTO>.self
        )

        guard response.success else {
            throw ticketError(response, fallbackCode: failureCode)
        }
    }

    private func findCreatedTicketID(for ticket: TicketCreate) async throws(NetworkError) -> Int64? {
        let tickets = try await fetchTickets()
        return tickets
            .filter { candidate in
                candidate.movieSeq == ticket.movieSeq
                && candidate.watchedDate == ticket.watchedDate
                && candidate.rating == ticket.rating
                && candidate.review.trimmingCharacters(in: .whitespacesAndNewlines) == (ticket.review ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .sorted { $0.createdAt > $1.createdAt }
            .first?
            .id
    }

    private func ticketError<T: Decodable & Equatable>(
        _ response: TicketAPIResponseDTO<T>,
        fallbackCode: String
    ) -> NetworkError {
        if response.message.isEmpty == false {
            return .apiError(code: String(response.code), message: response.message)
        }
        return .unknown(errorCode: fallbackCode)
    }
}
