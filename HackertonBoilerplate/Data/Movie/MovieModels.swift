import Foundation

struct MoviePageRequest: Equatable, Sendable {
    let keyword: String?
    let page: Int
    let size: Int
    let sort: [String]

    init(keyword: String? = nil, page: Int = 0, size: Int = 20, sort: [String] = []) {
        self.keyword = keyword
        self.page = page
        self.size = size
        self.sort = sort
    }

    var parameters: [String: Any] {
        var parameters: [String: Any] = [
            "page": page,
            "size": size
        ]
        if let keyword, keyword.isEmpty == false {
            parameters["keyword"] = keyword
        }
        if sort.isEmpty == false {
            parameters["sort"] = sort.joined(separator: ",")
        }
        return parameters
    }
}

struct MoviePage: Equatable, Sendable {
    let totalElements: Int64
    let totalPages: Int
    let size: Int
    let content: [MovieListItem]
    let number: Int
    let numberOfElements: Int
    let first: Bool
    let last: Bool
    let empty: Bool
}

struct MovieListItem: Equatable, Sendable {
    let seq: Int64
    let korTitle: String
    let engTitle: String
    let director: String
    let productionYear: String
    let genreName: String
    let imagePath: String
}

struct MovieDetail: Equatable, Sendable {
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
    let posterImageURLString: String?

    nonisolated init(
        seq: Int64,
        korTitle: String,
        engTitle: String,
        director: String,
        actors: String,
        productionYear: String,
        genreName: String,
        companyNm: String,
        distributorNm: String,
        imagePath: String,
        duration: String,
        rating: String,
        colorType: String,
        synopsis: String,
        screenwriter: String,
        producer: String,
        releaseDate: String,
        keywords: String,
        posterImageURLString: String? = nil
    ) {
        self.seq = seq
        self.korTitle = korTitle
        self.engTitle = engTitle
        self.director = director
        self.actors = actors
        self.productionYear = productionYear
        self.genreName = genreName
        self.companyNm = companyNm
        self.distributorNm = distributorNm
        self.imagePath = imagePath
        self.duration = duration
        self.rating = rating
        self.colorType = colorType
        self.synopsis = synopsis
        self.screenwriter = screenwriter
        self.producer = producer
        self.releaseDate = releaseDate
        self.keywords = keywords
        self.posterImageURLString = posterImageURLString
    }
}
