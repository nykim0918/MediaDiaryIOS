//
//  AppTheme.swift
//  MediaDiary
//

import SwiftUI

// MARK: - App Theme

enum AppTheme {

    // MARK: Colors

    static let accent = Color("AccentColor")

    // Gradient presets
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "8B5CF6"), Color(hex: "6366F1")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let warmGradient = LinearGradient(
        colors: [Color(hex: "F59E0B"), Color(hex: "EF4444")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let coolGradient = LinearGradient(
        colors: [Color(hex: "06B6D4"), Color(hex: "3B82F6")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // Adaptive surfaces
    static var surface: Color { Color(.secondarySystemBackground) }
    static var surface2: Color { Color(.tertiarySystemBackground) }
    static var bg: Color { Color(.systemBackground) }

    // Type colors
    static func typeColor(_ type: String) -> Color {
        switch type {
        case "movie":   return Color(hex: "3B82F6") // blue
        case "drama":   return Color(hex: "8B5CF6") // violet
        case "anime":   return Color(hex: "EC4899") // pink
        case "novel":   return Color(hex: "10B981") // emerald
        case "webtoon": return Color(hex: "F59E0B") // amber
        case "game":    return Color(hex: "EF4444") // red
        default:        return Color(.systemGray)
        }
    }

    static func typeGradient(_ type: String) -> LinearGradient {
        switch type {
        case "movie":
            return LinearGradient(colors: [Color(hex: "60A5FA"), Color(hex: "2563EB")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "drama":
            return LinearGradient(colors: [Color(hex: "A78BFA"), Color(hex: "7C3AED")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "anime":
            return LinearGradient(colors: [Color(hex: "F472B6"), Color(hex: "DB2777")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "novel":
            return LinearGradient(colors: [Color(hex: "34D399"), Color(hex: "059669")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "webtoon":
            return LinearGradient(colors: [Color(hex: "FCD34D"), Color(hex: "D97706")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "game":
            return LinearGradient(colors: [Color(hex: "FB923C"), Color(hex: "DC2626")], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [Color(.systemGray3), Color(.systemGray)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    // Status colors
    static func statusColor(_ status: String) -> Color {
        switch status {
        case "completed":  return Color(hex: "10B981")
        case "in_progress": return Color(hex: "3B82F6")
        case "want":       return Color(hex: "8B5CF6")
        case "dropped":    return Color(hex: "EF4444")
        default:           return Color(.systemGray)
        }
    }

    static func statusGradient(_ status: String) -> LinearGradient {
        switch status {
        case "completed":
            return LinearGradient(colors: [Color(hex: "34D399"), Color(hex: "059669")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "in_progress":
            return LinearGradient(colors: [Color(hex: "60A5FA"), Color(hex: "2563EB")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "want":
            return LinearGradient(colors: [Color(hex: "A78BFA"), Color(hex: "7C3AED")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "dropped":
            return LinearGradient(colors: [Color(hex: "F87171"), Color(hex: "DC2626")], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [Color(.systemGray3), Color(.systemGray)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    // MARK: Type icon (SF Symbol)
    static func typeIcon(_ type: String) -> String {
        switch type {
        case "movie":   return "movieclapper.fill"
        case "drama":   return "tv.fill"
        case "anime":   return "sparkles.tv.fill"
        case "novel":   return "character.book.closed.fill"
        case "webtoon": return "rectangle.stack.fill"
        case "game":    return "gamecontroller.fill"
        default:        return "photo.fill"
        }
    }

    // MARK: Type label
    static func typeLabel(_ type: String) -> String {
        switch type {
        case "movie":   return "영화"
        case "drama":   return "드라마"
        case "anime":   return "애니"
        case "novel":   return "소설"
        case "webtoon": return "웹툰"
        case "game":    return "게임"
        default:        return type
        }
    }

    // MARK: Status icon
    static func statusIcon(_ status: String) -> String {
        switch status {
        case "completed":  return "checkmark.seal.fill"
        case "in_progress": return "play.circle.fill"
        case "want":       return "heart.circle.fill"
        case "dropped":    return "xmark.circle.fill"
        default:           return "circle"
        }
    }

    // MARK: Status label
    static func statusLabel(_ status: String) -> String {
        switch status {
        case "completed":  return "완료"
        case "in_progress": return "보는 중"
        case "want":       return "보고 싶어요"
        case "dropped":    return "그만봤어요"
        default:           return status
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(
                color: colorScheme == .dark
                    ? Color.black.opacity(0.35)
                    : Color.black.opacity(0.08),
                radius: 12, x: 0, y: 4
            )
    }
}

struct GlassCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        colorScheme == .dark
                            ? Color.white.opacity(0.08)
                            : Color.white.opacity(0.6),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: colorScheme == .dark
                    ? Color.black.opacity(0.4)
                    : Color.black.opacity(0.1),
                radius: 16, x: 0, y: 6
            )
    }
}

struct PrimaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(AppTheme.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color(hex: "8B5CF6").opacity(0.35), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func glassCard() -> some View {
        modifier(GlassCardStyle())
    }

    func primaryButton() -> some View {
        modifier(PrimaryButtonStyle())
    }
}
