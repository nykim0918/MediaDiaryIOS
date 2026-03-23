//
//  ReviewBlock.swift
//  MediaDiary
//

import Foundation

// MARK: - Block Type

enum ReviewBlockType: String, Codable, CaseIterable {
    case paragraph  // 일반 텍스트
    case heading    // 제목 (굵게)
    case quote      // 인용구 (들여쓰기 + 강조)
    case image      // 사진 + 캡션
    case divider    // 구분선

    var displayName: String {
        switch self {
        case .paragraph: return "본문"
        case .heading:   return "제목"
        case .quote:     return "인용"
        case .image:     return "사진"
        case .divider:   return "구분선"
        }
    }

    var icon: String {
        switch self {
        case .paragraph: return "text.alignleft"
        case .heading:   return "textformat.size.larger"
        case .quote:     return "quote.opening"
        case .image:     return "photo"
        case .divider:   return "minus"
        }
    }
}

// MARK: - Block Model

struct ReviewBlock: Codable, Identifiable {
    var id: UUID
    var type: ReviewBlockType
    var text: String
    var imageFilename: String?  // for .image blocks (stored in Documents/ReviewImages/)
    var caption: String         // for .image blocks

    init(
        id: UUID = UUID(),
        type: ReviewBlockType = .paragraph,
        text: String = "",
        imageFilename: String? = nil,
        caption: String = ""
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.imageFilename = imageFilename
        self.caption = caption
    }
}
