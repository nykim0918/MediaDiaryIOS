//
//  BadgeView.swift
//  MediaDiary
//

import SwiftUI

// MARK: - TypeBadgeView

struct TypeBadgeView: View {
    let type: String
    var small: Bool = false
    /// Set true when the badge is overlaid on a dark poster image — uses white/frosted background
    var onPoster: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: AppTheme.typeIcon(type))
                .font(small ? .system(size: 9, weight: .bold) : .system(size: 10, weight: .bold))
            Text(AppTheme.typeLabel(type))
                .font(small ? .system(size: 10, weight: .semibold) : .system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, small ? 7 : 9)
        .padding(.vertical, small ? 3 : 4)
        .foregroundColor(onPoster ? .white : AppTheme.typeColor(type))
        .background(
            Group {
                if onPoster {
                    // White frosted background for dark poster surfaces
                    ZStack {
                        Color.white.opacity(0.22)
                        AppTheme.typeGradient(type).opacity(0.35)
                    }
                } else {
                    AppTheme.typeGradient(type).opacity(0.15)
                }
            }
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    onPoster ? Color.white.opacity(0.4) : AppTheme.typeColor(type).opacity(0.25),
                    lineWidth: 0.5
                )
        )
    }
}

// MARK: - StatusBadgeView

struct StatusBadgeView: View {
    let status: String
    var small: Bool = false
    var onPoster: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: AppTheme.statusIcon(status))
                .font(small ? .system(size: 9, weight: .bold) : .system(size: 10, weight: .bold))
            Text(AppTheme.statusLabel(status))
                .font(small ? .system(size: 10, weight: .semibold) : .system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, small ? 7 : 9)
        .padding(.vertical, small ? 3 : 4)
        .foregroundColor(onPoster ? .white : AppTheme.statusColor(status))
        .background(
            Group {
                if onPoster {
                    ZStack {
                        Color.white.opacity(0.22)
                        AppTheme.statusGradient(status).opacity(0.35)
                    }
                } else {
                    AppTheme.statusGradient(status).opacity(0.15)
                }
            }
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    onPoster ? Color.white.opacity(0.4) : AppTheme.statusColor(status).opacity(0.25),
                    lineWidth: 0.5
                )
        )
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                TypeBadgeView(type: "movie")
                TypeBadgeView(type: "drama")
                TypeBadgeView(type: "anime")
                TypeBadgeView(type: "novel")
                TypeBadgeView(type: "webtoon")
            }
            HStack(spacing: 8) {
                StatusBadgeView(status: "completed")
                StatusBadgeView(status: "in_progress")
                StatusBadgeView(status: "want")
                StatusBadgeView(status: "dropped")
            }
        }
        .padding()
    }
}
