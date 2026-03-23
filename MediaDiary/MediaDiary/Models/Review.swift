//
//  Review.swift
//  MediaDiary
//

import Foundation
import SwiftData

@Model
class Review {
    var rating: Double?
    var status: String
    var content: String?
    var richContent: Data?      // JSON-encoded [ReviewBlock] for rich editor
    var startedAt: Date?
    var finishedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    var tags: [String]

    @Relationship(inverse: \Work.review)
    var work: Work?

    init(
        rating: Double? = nil,
        status: String = "want",
        content: String? = nil,
        richContent: Data? = nil,
        startedAt: Date? = nil,
        finishedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        tags: [String] = []
    ) {
        self.rating = rating
        self.status = status
        self.content = content
        self.richContent = richContent
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = tags
    }

    /// Decode stored JSON blocks
    var richBlocks: [ReviewBlock] {
        get {
            guard let data = richContent else { return [] }
            return (try? JSONDecoder().decode([ReviewBlock].self, from: data)) ?? []
        }
        set {
            richContent = try? JSONEncoder().encode(newValue)
        }
    }

    var statusLabel: String {
        switch status {
        case "completed":  return "완료"
        case "in_progress": return "보는 중"
        case "want":       return "보고 싶어요"
        case "dropped":    return "그만봤어요"
        default: return status
        }
    }
}
