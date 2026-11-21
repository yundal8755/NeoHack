import Foundation

enum MovieMapper {
    nonisolated static func map(_ dto: MoviePageResponseDTO) -> MoviePage {
        MoviePage(
            totalElements: dto.totalElements,
            totalPages: dto.totalPages,
            size: dto.size,
            content: dto.content.map(map),
            number: dto.number,
            numberOfElements: dto.numberOfElements,
            first: dto.first,
            last: dto.last,
            empty: dto.empty
        )
    }

    nonisolated static func map(_ dto: MovieListResponseDTO) -> MovieListItem {
        MovieListItem(
            seq: dto.seq,
            korTitle: dto.korTitle,
            engTitle: dto.engTitle,
            director: dto.director,
            productionYear: dto.productionYear,
            genreName: dto.genreName,
            imagePath: dto.imagePath
        )
    }

    nonisolated static func map(_ dto: MovieDetailResponseDTO) -> MovieDetail {
        MovieDetail(
            seq: dto.seq,
            korTitle: dto.korTitle,
            engTitle: dto.engTitle,
            director: dto.director,
            actors: dto.actors,
            productionYear: dto.productionYear,
            genreName: dto.genreName,
            companyNm: dto.companyNm,
            distributorNm: dto.distributorNm,
            imagePath: dto.imagePath,
            duration: dto.duration,
            rating: dto.rating,
            colorType: dto.colorType,
            synopsis: dto.synopsis,
            screenwriter: dto.screenwriter,
            producer: dto.producer,
            releaseDate: dto.releaseDate,
            keywords: dto.keywords,
            posterImageURLString: MovieEndpoint.imageURLString(imagePath: dto.imagePath)
        )
    }

    nonisolated static func map(_ movie: RecordMovie) -> MovieDetail {
        MovieDetail(
            seq: movie.seq,
            korTitle: movie.title,
            engTitle: "",
            director: movie.director,
            actors: "",
            productionYear: movie.releaseYear.map(String.init) ?? "",
            genreName: movie.genre,
            companyNm: "",
            distributorNm: "",
            imagePath: "",
            duration: movie.runningTimeMinutes.map(String.init) ?? "",
            rating: "",
            colorType: "",
            synopsis: "",
            screenwriter: "",
            producer: "",
            releaseDate: "",
            keywords: "",
            posterImageURLString: movie.posterImageURLString
        )
    }
}
