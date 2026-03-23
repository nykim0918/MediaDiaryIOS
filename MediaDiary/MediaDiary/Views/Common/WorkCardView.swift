//
//  WorkCardView.swift
//  MediaDiary
//

import SwiftUI

// MARK: - Grid Card

struct WorkCardView: View {
    let work: Work
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Poster area
            ZStack(alignment: .bottom) {
                PosterImageView(urlString: work.posterURL, height: 200, type: work.type)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()

                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)

                // Bottom badges row
                HStack(spacing: 4) {
                    TypeBadgeView(type: work.type, small: true, onPoster: true)
                    if let review = work.review {
                        StatusBadgeView(status: review.status, small: true, onPoster: true)
                    }
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .overlay(alignment: .topTrailing) {
                // Rating pill (top right)
                if let rating = work.review?.rating, rating > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(8)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(work.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let tags = work.review?.tags, !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(tags.prefix(3), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(
            color: colorScheme == .dark ? .black.opacity(0.35) : .black.opacity(0.1),
            radius: 10, x: 0, y: 4
        )
    }
}

// MARK: - List Row

struct WorkRowView: View {
    let work: Work
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            // Poster
            ZStack(alignment: .bottomTrailing) {
                PosterImageView(urlString: work.posterURL, height: 80, type: work.type)
                    .frame(width: 56, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                // Status dot
                if let status = work.review?.status {
                    ZStack {
                        Circle()
                            .fill(AppTheme.statusGradient(status))
                            .frame(width: 14, height: 14)
                        Circle()
                            .stroke(AppTheme.surface, lineWidth: 1.5)
                            .frame(width: 14, height: 14)
                    }
                    .offset(x: 3, y: 3)
                }
            }
            .shadow(color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.12), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 5) {
                Text(work.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                HStack(spacing: 5) {
                    TypeBadgeView(type: work.type, small: true)
                    if let review = work.review {
                        StatusBadgeView(status: review.status, small: true)
                    }
                }

                if let rating = work.review?.rating, rating > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }

                if let tags = work.review?.tags, !tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Poster Image

struct PosterImageView: View {
    let urlString: String?
    let height: CGFloat
    var type: String = ""

    var body: some View {
        if let urlString, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            AppTheme.typeGradient(type)
            VStack(spacing: 8) {
                Image(systemName: AppTheme.typeIcon(type.isEmpty ? "movie" : type))
                    .font(.system(size: min(height * 0.25, 36), weight: .light))
                    .foregroundColor(.white.opacity(0.85))
            }
        }
    }
}
