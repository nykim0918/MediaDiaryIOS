//
//  Work.swift
//  MediaDiary
//

import Foundation
import SwiftData

@Model
class Work {
    var id: UUID
    var title: String
    var type: String
    var year: String?
    var genre: String?
    var author: String?
    var posterURL: String?
    var workDescription: String?
    var platform: String?
    var externalID: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var review: Review?

    init(
        id: UUID = UUID(),
        title: String,
        type: String,
        year: String? = nil,
        genre: String? = nil,
        author: String? = nil,
        posterURL: String? = nil,
        workDescription: String? = nil,
        platform: String? = nil,
        externalID: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.year = year
        self.genre = genre
        self.author = author
        self.posterURL = posterURL
        self.workDescription = workDescription
        self.platform = platform
        self.externalID = externalID
        self.createdAt = createdAt
    }

    var typeLabel: String {
        switch type {
        case "movie":   return "🎬 영화"
        case "drama":   return "📺 드라마"
        case "anime":   return "🎌 애니"
        case "novel":   return "📚 소설"
        case "webtoon": return "📖 웹툰"
        case "game":    return "🎮 게임"
        default: return type
        }
    }

    var typeColor: String {
        switch type {
        case "movie":   return "blue"
        case "drama":   return "purple"
        case "anime":   return "pink"
        case "novel":   return "green"
        case "webtoon": return "orange"
        case "game":    return "red"
        default: return "gray"
        }
    }
}
