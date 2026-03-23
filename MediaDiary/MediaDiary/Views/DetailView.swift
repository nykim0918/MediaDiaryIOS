//
//  DetailView.swift
//  MediaDiary
//

import SwiftUI
import SwiftData

struct DetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let work: Work

    @State private var showEditSheet = false
    @State private var showDeleteAlert = false

    private var posterURLHD: String? {
        guard let url = work.posterURL else { return nil }
        return url
            .replacingOccurrences(of: "/w342/", with: "/w780/")
            .replacingOccurrences(of: "/w500/", with: "/w780/")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                cinematicHeader
                VStack(alignment: .leading, spacing: 24) {
                    titleBlock
                    if work.year != nil || work.genre != nil || work.author != nil || work.platform != nil {
                        metaBlock
                    }
                    if let desc = work.workDescription, !desc.isEmpty {
                        descriptionBlock(desc)
                    }
                    reviewBlock
                    actionButtons
                }
                .padding(20)
                .padding(.bottom, 20)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { showEditSheet = true } label: {
                        Label("수정하기", systemImage: "pencil.circle")
                    }
                    Button(role: .destructive) { showDeleteAlert = true } label: {
                        Label("삭제하기", systemImage: "trash")
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "8B5CF6").opacity(0.12))
                            .frame(width: 34, height: 34)
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "8B5CF6"))
                    }
                }
            }
        }
        .sheet(isPresented: $showEditSheet) { EditReviewSheet(work: work) }
        .alert("작품 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) { deleteWork() }
        } message: {
            Text("'\(work.title)'을(를) 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.")
        }
    }

    // MARK: - Cinematic Header

    private var cinematicHeader: some View {
        ZStack(alignment: .bottom) {
            // Blurred background
            Group {
                if let urlStr = posterURLHD ?? work.posterURL, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            AppTheme.typeGradient(work.type)
                        }
                    }
                } else {
                    AppTheme.typeGradient(work.type)
                }
            }
            .frame(height: 300)
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [
                        .black.opacity(0.2),
                        .black.opacity(0.7),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Poster + info overlay
            HStack(alignment: .bottom, spacing: 16) {
                PosterImageView(urlString: posterURLHD ?? work.posterURL, height: 200, type: work.type)
                    .frame(width: 134, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.5), radius: 16, x: 0, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        TypeBadgeView(type: work.type, onPoster: true)
                        if let status = work.review?.status {
                            StatusBadgeView(status: status, onPoster: true)
                        }
                    }

                    Text(work.title)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

                    if let rating = work.review?.rating, rating > 0 {
                        HStack(spacing: 5) {
                            ForEach(0..<5) { i in
                                Image(systemName: Double(i) + 0.5 <= rating ? "star.fill" : (Double(i) < rating ? "star.leadinghalf.filled" : "star"))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.yellow)
                            }
                            Text(String(format: "%.1f", rating))
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
                .padding(.bottom, 4)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
        }
        .frame(height: 300)
    }

    // MARK: - Title Block

    private var titleBlock: some View {
        Text(work.title)
            .font(.title2.weight(.bold))
            .foregroundColor(.primary)
    }

    // MARK: - Meta Block

    private var metaBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryGradient)
                Text("작품 정보")
                    .font(.headline.weight(.bold))
            }

            VStack(spacing: 0) {
                metaRows
            }
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.06), radius: 10, x: 0, y: 3)
        }
    }

    @ViewBuilder
    private var metaRows: some View {
        if let year = work.year {
            MetaRow(icon: "calendar.circle.fill", label: "연도", value: year, color: Color(hex: "3B82F6"))
        }
        if let genre = work.genre {
            Divider().padding(.leading, 56)
            MetaRow(icon: "tag.circle.fill", label: "장르", value: genre, color: Color(hex: "8B5CF6"))
        }
        if let author = work.author {
            Divider().padding(.leading, 56)
            MetaRow(icon: "person.circle.fill", label: "감독/작가", value: author, color: Color(hex: "10B981"))
        }
        if let platform = work.platform {
            Divider().padding(.leading, 56)
            MetaRow(icon: "play.circle.fill", label: "플랫폼", value: platform, color: Color(hex: "F59E0B"))
        }
    }

    // MARK: - Description Block

    private func descriptionBlock(_ desc: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryGradient)
                Text("줄거리")
                    .font(.headline.weight(.bold))
            }

            Text(desc)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(nil)
                .lineSpacing(4)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: colorScheme == .dark ? .black.opacity(0.25) : .black.opacity(0.05), radius: 8, x: 0, y: 3)
        }
    }

    // MARK: - Review Block

    @ViewBuilder
    private var reviewBlock: some View {
        if let review = work.review {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 7) {
                    Image(systemName: "star.bubble.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryGradient)
                    Text("감상 기록")
                        .font(.headline.weight(.bold))
                }

                VStack(spacing: 0) {
                    // Rating row
                    if let rating = review.rating, rating > 0 {
                        HStack(spacing: 14) {
                            ZStack {
                                AppTheme.warmGradient
                                Image(systemName: "star.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .shadow(color: Color(hex: "F59E0B").opacity(0.3), radius: 4, x: 0, y: 2)

                            VStack(alignment: .leading, spacing: 3) {
                                StarRatingDisplayView(rating: rating, starSize: 15)
                                Text(String(format: "%.1f / 5.0", rating))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(14)

                        Divider().padding(.leading, 56)
                    }

                    // Start date
                    if let started = review.startedAt {
                        HStack(spacing: 14) {
                            ZStack {
                                LinearGradient(colors: [Color(hex: "34D399"), Color(hex: "059669")], startPoint: .topLeading, endPoint: .bottomTrailing)
                                Image(systemName: "play.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .shadow(color: Color(hex: "10B981").opacity(0.3), radius: 4, x: 0, y: 2)

                            Text("시작일")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(started.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline.weight(.semibold))
                        }
                        .padding(14)

                        Divider().padding(.leading, 56)
                    }

                    // Finish date
                    if let finished = review.finishedAt {
                        HStack(spacing: 14) {
                            ZStack {
                                LinearGradient(colors: [Color(hex: "60A5FA"), Color(hex: "2563EB")], startPoint: .topLeading, endPoint: .bottomTrailing)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .shadow(color: Color(hex: "3B82F6").opacity(0.3), radius: 4, x: 0, y: 2)

                            Text("완료일")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(finished.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline.weight(.semibold))
                        }
                        .padding(14)

                        let hasReviewContent = !review.richBlocks.isEmpty || (review.content != nil && !review.content!.isEmpty)
                        if hasReviewContent {
                            Divider().padding(.leading, 56)
                        }
                    }

                    // Review content — rich blocks take priority over legacy plain text
                    let blocks = review.richBlocks
                    if !blocks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "quote.bubble.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "8B5CF6"))
                                Text("감상평")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.secondary)
                            }
                            RichContentView(blocks: blocks)
                        }
                        .padding(14)
                    } else if let content = review.content, !content.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "quote.bubble.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "8B5CF6"))
                                Text("감상평")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.secondary)
                            }
                            Text(content)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(nil)
                                .lineSpacing(3)
                        }
                        .padding(14)
                    }
                }
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.06), radius: 10, x: 0, y: 3)

                // Tags
                if !review.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "8B5CF6"))
                            Text("태그")
                                .font(.subheadline.weight(.semibold))
                        }

                        FlowLayout(spacing: 8) {
                            ForEach(review.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(Color(hex: "8B5CF6").opacity(0.1))
                                    .foregroundColor(Color(hex: "8B5CF6"))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color(hex: "8B5CF6").opacity(0.2), lineWidth: 0.5))
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button { showEditSheet = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 16))
                    Text("리뷰 수정하기")
                }
                .primaryButton()
            }

            Button { showDeleteAlert = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 16))
                    Text("작품 삭제")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color(.systemRed).opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.red.opacity(0.15), lineWidth: 1)
                )
            }
        }
    }

    private func deleteWork() {
        modelContext.delete(work)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - MetaRow

struct MetaRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }
}
