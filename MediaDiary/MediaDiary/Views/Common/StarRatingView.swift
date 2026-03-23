//
//  StarRatingView.swift
//  MediaDiary
//

import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Double
    var isEditable: Bool = true
    var starSize: CGFloat = 24

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                starImage(for: star)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: starSize, height: starSize)
                    .foregroundColor(.yellow)
                    .onTapGesture {
                        if isEditable {
                            handleTap(star: star)
                        }
                    }
            }
        }
        .gesture(
            isEditable ? DragGesture(minimumDistance: 0)
                .onChanged { value in
                    updateRating(from: value.location.x)
                } : nil
        )
    }

    private func starImage(for star: Int) -> Image {
        let filled = Double(star) <= rating
        let halfFilled = Double(star) - 0.5 <= rating && Double(star) > rating
        if filled {
            return Image(systemName: "star.fill")
        } else if halfFilled {
            return Image(systemName: "star.leadinghalf.filled")
        } else {
            return Image(systemName: "star")
        }
    }

    private func handleTap(star: Int) {
        let full = Double(star)
        let half = Double(star) - 0.5
        if rating == full {
            rating = half
        } else if rating == half {
            rating = 0
        } else {
            rating = full
        }
    }

    private func updateRating(from x: CGFloat) {
        let totalWidth = starSize * 5 + 4 * 4
        let clampedX = max(0, min(x, totalWidth))
        let rawRating = (clampedX / totalWidth) * 5.0
        let snapped = (rawRating * 2).rounded() / 2
        rating = min(5.0, max(0, snapped))
    }
}

struct StarRatingDisplayView: View {
    let rating: Double
    var starSize: CGFloat = 16

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                starImage(for: star)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: starSize, height: starSize)
                    .foregroundColor(.yellow)
            }
        }
    }

    private func starImage(for star: Int) -> Image {
        let filled = Double(star) <= rating
        let halfFilled = Double(star) - 0.5 <= rating && Double(star) > rating
        if filled {
            return Image(systemName: "star.fill")
        } else if halfFilled {
            return Image(systemName: "star.leadinghalf.filled")
        } else {
            return Image(systemName: "star")
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StarRatingView(rating: .constant(3.5))
        StarRatingDisplayView(rating: 4.0)
        StarRatingDisplayView(rating: 2.5)
    }
    .padding()
}
