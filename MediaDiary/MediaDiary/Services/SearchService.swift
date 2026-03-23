//
//  SearchService.swift
//  MediaDiary
//

import Foundation

struct SearchResult: Identifiable {
    let id = UUID()
    var title: String
    var type: String
    var year: String?
    var genre: String?
    var author: String?
    var posterURL: String?
    var description: String?
    var platform: String?
    var externalID: String?
}

enum SearchError: LocalizedError {
    case noAPIKey(String)
    case networkError(Error)
    case decodingError(Error)
    case noResults

    var errorDescription: String? {
        switch self {
        case .noAPIKey(let key): return "\(key) API 키가 설정되지 않았습니다. 설정에서 입력해 주세요."
        case .networkError(let e): return "네트워크 오류: \(e.localizedDescription)"
        case .decodingError(let e): return "데이터 파싱 오류: \(e.localizedDescription)"
        case .noResults: return "검색 결과가 없습니다."
        }
    }
}

// MARK: - TMDB Genre Map
private let tmdbMovieGenres: [Int: String] = [
    28: "액션", 12: "모험", 16: "애니메이션", 35: "코미디", 80: "범죄",
    99: "다큐멘터리", 18: "드라마", 10751: "가족", 14: "판타지", 36: "역사",
    27: "공포", 10402: "음악", 9648: "미스터리", 10749: "로맨스",
    878: "SF", 10770: "TV 영화", 53: "스릴러", 10752: "전쟁", 37: "서부"
]

private let tmdbDramaGenres: [Int: String] = [
    10759: "액션·어드벤처", 16: "애니메이션", 35: "코미디", 80: "범죄",
    99: "다큐멘터리", 18: "드라마", 10751: "가족", 10762: "키즈",
    9648: "미스터리", 10763: "뉴스", 10764: "리얼리티", 10765: "SF·판타지",
    10766: "연속극", 10767: "토크", 10768: "전쟁·정치", 37: "서부"
]

// MARK: - SearchService
@MainActor
class SearchService {

    static let shared = SearchService()
    private init() {}

    private var tmdbAPIKey: String? {
        let key = UserDefaults.standard.string(forKey: "tmdb_api_key") ?? ""
        return key.isEmpty ? nil : key
    }

    private var kakaoAPIKey: String? {
        let key = UserDefaults.standard.string(forKey: "kakao_api_key") ?? ""
        return key.isEmpty ? nil : key
    }

    private let tmdbBaseURL = "https://api.themoviedb.org/3"
    private let tmdbImageURL = "https://image.tmdb.org/t/p/w342"

    // MARK: - TMDB Search (movie / drama)
    func searchTMDB(query: String, type: String) async throws -> [SearchResult] {
        guard let apiKey = tmdbAPIKey else {
            throw SearchError.noAPIKey("TMDB")
        }

        let endpoint = type == "movie" ? "movie" : "tv"
        let language = "ko-KR"
        var components = URLComponents(string: "\(tmdbBaseURL)/search/\(endpoint)")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "include_adult", value: "false")
        ]

        guard let url = components.url else { throw SearchError.noResults }

        let (data, _): (Data, URLResponse)
        do {
            (data, _) = try await URLSession.shared.data(from: url)
        } catch {
            throw SearchError.networkError(error)
        }

        // Try to decode
        if type == "movie" {
            struct TMDBMovieResponse: Decodable {
                struct Movie: Decodable {
                    let id: Int
                    let title: String
                    let release_date: String?
                    let genre_ids: [Int]?
                    let poster_path: String?
                    let overview: String?
                }
                let results: [Movie]
            }
            do {
                let response = try JSONDecoder().decode(TMDBMovieResponse.self, from: data)
                return response.results.map { movie in
                    let genreNames = (movie.genre_ids ?? []).compactMap { tmdbMovieGenres[$0] }.joined(separator: ", ")
                    let year = movie.release_date.flatMap { $0.prefix(4).isEmpty ? nil : String($0.prefix(4)) }
                    let poster = movie.poster_path.map { "\(tmdbImageURL)\($0)" }
                    return SearchResult(
                        title: movie.title,
                        type: "movie",
                        year: year,
                        genre: genreNames.isEmpty ? nil : genreNames,
                        author: nil,
                        posterURL: poster,
                        description: movie.overview,
                        platform: nil,
                        externalID: String(movie.id)
                    )
                }
            } catch {
                throw SearchError.decodingError(error)
            }
        } else {
            struct TMDBTVResponse: Decodable {
                struct TV: Decodable {
                    let id: Int
                    let name: String
                    let first_air_date: String?
                    let genre_ids: [Int]?
                    let poster_path: String?
                    let overview: String?
                    let origin_country: [String]?
                }
                let results: [TV]
            }
            do {
                let response = try JSONDecoder().decode(TMDBTVResponse.self, from: data)
                return response.results.map { tv in
                    let genreNames = (tv.genre_ids ?? []).compactMap { tmdbDramaGenres[$0] }.joined(separator: ", ")
                    let year = tv.first_air_date.flatMap { $0.prefix(4).isEmpty ? nil : String($0.prefix(4)) }
                    let poster = tv.poster_path.map { "\(tmdbImageURL)\($0)" }
                    return SearchResult(
                        title: tv.name,
                        type: "drama",
                        year: year,
                        genre: genreNames.isEmpty ? nil : genreNames,
                        author: nil,
                        posterURL: poster,
                        description: tv.overview,
                        platform: nil,
                        externalID: String(tv.id)
                    )
                }
            } catch {
                throw SearchError.decodingError(error)
            }
        }
    }

    // MARK: - Anime Search (AniList + Jikan 병렬 검색, 한국어/영어/일본어 모두 지원)
    func searchAnime(query: String) async throws -> [SearchResult] {
        // Run both APIs in parallel
        async let anilistResults = searchAniList(query: query)
        async let jikanResults = searchJikan(query: query)

        var combined: [SearchResult] = []
        if let results = try? await anilistResults { combined += results }
        if let results = try? await jikanResults { combined += results }

        // Deduplicate by title (case-insensitive)
        var seen = Set<String>()
        combined = combined.filter { seen.insert($0.title.lowercased()).inserted }

        if combined.isEmpty { throw SearchError.noResults }
        return Array(combined.prefix(20))
    }

    // MARK: - AniList GraphQL Search (무료, API 키 불필요, 한국어 지원 우수)
    private func searchAniList(query: String) async throws -> [SearchResult] {
        let graphqlQuery = """
        {"query":"query($search:String){Page(perPage:20){media(search:$search,type:ANIME,sort:SEARCH_MATCH){id title{romaji english native}startDate{year}genres coverImage{large}description(asHtml:false)studios(isMain:true){nodes{name}}}}}","variables":{"search":"\(query.replacingOccurrences(of: "\"", with: "\\\""))"}}
        """
        guard let url = URL(string: "https://graphql.anilist.co"),
              let body = graphqlQuery.data(using: .utf8) else {
            throw SearchError.noResults
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: request)

        struct AniListResponse: Decodable {
            struct Data: Decodable {
                struct Page: Decodable {
                    struct Media: Decodable {
                        let id: Int
                        struct Title: Decodable {
                            let romaji: String?
                            let english: String?
                            let native: String?
                        }
                        let title: Title
                        struct StartDate: Decodable { let year: Int? }
                        let startDate: StartDate?
                        let genres: [String]?
                        struct CoverImage: Decodable { let large: String? }
                        let coverImage: CoverImage?
                        let description: String?
                        struct Studios: Decodable {
                            struct Node: Decodable { let name: String }
                            let nodes: [Node]
                        }
                        let studios: Studios?
                    }
                    let media: [Media]
                }
                let Page: Page
            }
            let data: Data?
        }

        let response = try JSONDecoder().decode(AniListResponse.self, from: data)
        return (response.data?.Page.media ?? []).map { media in
            // Prefer: English → Romaji → Native title
            let title = media.title.english ?? media.title.romaji ?? media.title.native ?? "Unknown"
            let year = media.startDate?.year.map { String($0) }
            let genre = media.genres?.prefix(3).joined(separator: ", ")
            return SearchResult(
                title: title,
                type: "anime",
                year: year,
                genre: genre,
                author: media.studios?.nodes.first?.name,
                posterURL: media.coverImage?.large,
                description: media.description,
                platform: nil,
                externalID: String(media.id)
            )
        }
    }

    // MARK: - Jikan Search (MAL 기반, 영어/일본어)
    private func searchJikan(query: String) async throws -> [SearchResult] {
        var components = URLComponents(string: "https://api.jikan.moe/v4/anime")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: "20")
        ]

        guard let url = components.url else { throw SearchError.noResults }

        let (data, _): (Data, URLResponse)
        do {
            (data, _) = try await URLSession.shared.data(from: url)
        } catch {
            throw SearchError.networkError(error)
        }

        struct JikanResponse: Decodable {
            struct Anime: Decodable {
                let mal_id: Int
                let title: String
                let title_japanese: String?
                let aired: Aired?
                let genres: [Genre]?
                let images: Images?
                let synopsis: String?
                let studios: [Studio]?

                struct Aired: Decodable {
                    let prop: Prop?
                    struct Prop: Decodable {
                        let from: FromTo?
                        struct FromTo: Decodable {
                            let year: Int?
                        }
                    }
                }
                struct Genre: Decodable {
                    let name: String
                }
                struct Images: Decodable {
                    let jpg: ImageURL?
                    struct ImageURL: Decodable {
                        let image_url: String?
                        let large_image_url: String?
                    }
                }
                struct Studio: Decodable {
                    let name: String
                }
            }
            let data: [Anime]
        }

        do {
            let response = try JSONDecoder().decode(JikanResponse.self, from: data)
            return response.data.map { anime in
                let year = anime.aired?.prop?.from?.year.map { String($0) }
                let genre = anime.genres?.map { $0.name }.joined(separator: ", ")
                let poster = anime.images?.jpg?.large_image_url ?? anime.images?.jpg?.image_url
                return SearchResult(
                    title: anime.title,
                    type: "anime",
                    year: year,
                    genre: genre,
                    author: anime.studios?.first?.name,
                    posterURL: poster,
                    description: anime.synopsis,
                    platform: nil,
                    externalID: String(anime.mal_id)
                )
            }
        } catch {
            throw SearchError.decodingError(error)
        }
    }  // end searchJikan

    // MARK: - Kakao Books Search (novel / webtoon)
    func searchBooks(query: String, type: String) async throws -> [SearchResult] {
        guard let apiKey = kakaoAPIKey else {
            throw SearchError.noAPIKey("Kakao")
        }

        var components = URLComponents(string: "https://dapi.kakao.com/v3/search/book")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "size", value: "20")
        ]

        guard let url = components.url else { throw SearchError.noResults }

        var request = URLRequest(url: url)
        request.setValue("KakaoAK \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, _): (Data, URLResponse)
        do {
            (data, _) = try await URLSession.shared.data(for: request)
        } catch {
            throw SearchError.networkError(error)
        }

        struct KakaoResponse: Decodable {
            struct Document: Decodable {
                let title: String
                let authors: [String]?
                let datetime: String?
                let genre: String?
                let thumbnail: String?
                let contents: String?
                let publisher: String?
                let isbn: String?
            }
            let documents: [Document]
        }

        do {
            let response = try JSONDecoder().decode(KakaoResponse.self, from: data)
            return response.documents.map { doc in
                let year = doc.datetime.flatMap { $0.prefix(4).isEmpty ? nil : String($0.prefix(4)) }
                return SearchResult(
                    title: doc.title,
                    type: type,
                    year: year,
                    genre: doc.genre,
                    author: doc.authors?.joined(separator: ", "),
                    posterURL: doc.thumbnail,
                    description: doc.contents,
                    platform: doc.publisher,
                    externalID: doc.isbn
                )
            }
        } catch {
            throw SearchError.decodingError(error)
        }
    }
}
