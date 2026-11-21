import Alamofire
import Foundation

enum TicketEndpoint: TargetType {
    case list
    case publicList(sort: String = "latest")
    case create(TicketCreateRequestDTO)
    case detail(ticketId: Int64)
    case update(ticketId: Int64, request: TicketUpdateRequestDTO)
    case delete(ticketId: Int64)
    case share(ticketId: Int64, showYn: Bool)

    var method: HTTPMethod {
        switch self {
        case .list, .publicList, .detail:
            .get
        case .create:
            .post
        case .update, .share:
            .patch
        case .delete:
            .delete
        }
    }

    var path: String {
        switch self {
        case .list, .create:
            "/api/tickets"
        case .publicList:
            "/api/tickets/public"
        case .detail(let ticketId), .delete(let ticketId):
            "/api/tickets/\(ticketId)"
        case .update(let ticketId, _):
            "/api/tickets/\(ticketId)"
        case .share(let ticketId, _):
            "/api/tickets/\(ticketId)/share"
        }
    }

    var optionalHeaders: HTTPHeaders? {
        nil
    }

    var parameters: Parameters? {
        switch self {
        case .publicList(let sort):
            ["sort": sort]
        case .share(_, let showYn):
            ["showYn": showYn]
        case .list, .create, .detail, .update, .delete:
            nil
        }
    }

    var body: Data? {
        switch self {
        case .list, .publicList, .detail, .delete, .share:
            nil
        case .create(let request):
            requestToBody(request)
        case .update(_, let request):
            requestToBody(request)
        }
    }

    var encodingType: EncodingType {
        switch self {
        case .list, .publicList, .detail, .delete, .share:
            .url
        case .create, .update:
            .json
        }
    }

    var requiresAuthentication: Bool {
        switch self {
        case .publicList:
            false
        case .list, .create, .detail, .update, .delete, .share:
            true
        }
    }
}
