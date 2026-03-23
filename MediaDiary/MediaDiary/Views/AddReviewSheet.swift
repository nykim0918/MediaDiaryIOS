//
//  AddReviewSheet.swift
//  MediaDiary
//

import SwiftUI
import SwiftData

struct AddReviewSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let searchResult: SearchResult
    var onSaved: (() -> Void)?

    @State private var rating: Double = 0
    @State private var status: String = "want"
    @State private var reviewContent: String = ""
    @State private var startedAt: Date = Date()
    @State private var finishedAt: Date = Date()
    @State private var showStartDate: Bool = false
    @State private var showFinishDate: Bool = false
    @State private var tagInput: String = ""
    @State private var selectedTags: [String] = []
    @State private var richBlocks: [ReviewBlock] = []
    @State private var isSaving: Bool = false

    private let statuses = [
        ("completed", "완료", "checkmark.seal.fill"),
        ("in_progress", "보는 중", "play.circle.fill"),
        ("want", "보고 싶어요", "heart.circle.fill"),
        ("dropped", "그만봤어요", "xmark.circle.fill")
    ]

    private var suggestedKeywords: [String] {
        KeywordService.shared.keywords(for: searchResult.type, genre: searchResult.genre)
            .filter { !selectedTags.contains($0) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero preview
                    workHeroSection

                    VStack(spacing: 24) {
                        ratingSection
                        statusSection
                        datesSection
                        reviewSection
                        tagsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("작품 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장하기") { saveWork() }
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "8B5CF6"))
                        .disabled(isSaving)
                }
            }
        }
    }

    // MARK: - Hero Section

    private var workHeroSection: some View {
        ZStack(alignment: .bottom) {
            // Background
            AppTheme.typeGradient(searchResult.type)
                .frame(height: 180)
                .overlay(Color.black.opacity(0.35))

            HStack(alignment: .bottom, spacing: 16) {
                PosterImageView(urlString: searchResult.posterURL, height: 160, type: searchResult.type)
                    .frame(width: 108, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    TypeBadgeView(type: searchResult.type, onPoster: true)

                    Text(searchResult.title)
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .lineLimit(3)

                    VStack(alignment: .leading, spacing: 3) {
                        if let year = searchResult.year {
                            Label(year, systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.75))
                        }
                        if let genre = searchResult.genre {
                            Label(genre, systemImage: "tag.fill")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.75))
                                .lineLimit(1)
                        }
                        if let author = searchResult.author {
                            Label(author, systemImage: "person.fill")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.75))
                        }
                    }
                }
                .padding(.bottom, 2)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(height: 180)
    }

    // MARK: - Rating Section

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("평점", icon: "star.fill", color: Color(hex: "F59E0B"))

            VStack(spacing: 10) {
                HStack {
                    StarRatingView(rating: $rating, isEditable: true, starSize: 36)
                    Spacer()
                    Text(rating > 0 ? String(format: "%.1f", rating) : "미평가")
                        .font(.title3.weight(.bold))
                        .foregroundColor(rating > 0 ? .primary : .secondary)
                        .animation(.easeInOut(duration: 0.2), value: rating)
                }

                if rating > 0 {
                    Button {
                        withAnimation { rating = 0 }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 11))
                            Text("평점 초기화")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: colorScheme == .dark ? .black.opacity(0.25) : .black.opacity(0.05), radius: 8, x: 0, y: 3)
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("상태", icon: "circle.hexagongrid.fill", color: Color(hex: "8B5CF6"))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(statuses, id: \.0) { statusValue, statusLabel, statusIcon in
                    let isSelected = status == statusValue
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            status = statusValue
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: statusIcon)
                                .font(.system(size: 14, weight: .semibold))
                            Text(statusLabel)
                                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            isSelected
                                ? AnyView(AppTheme.statusGradient(statusValue))
                                : AnyView(AppTheme.surface)
                        )
                        .foregroundColor(isSelected ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(
                            color: isSelected ? AppTheme.statusColor(statusValue).opacity(0.3) : .clear,
                            radius: 6, x: 0, y: 3
                        )
                    }
                }
            }
        }
    }

    // MARK: - Dates Section

    private var datesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("날짜", icon: "calendar.circle.fill", color: Color(hex: "10B981"))

            VStack(spacing: 0) {
                // Start date
                VStack(spacing: 0) {
                    Toggle(isOn: $showStartDate) {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "10B981").opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "play.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(hex: "10B981"))
                            }
                            Text("시작일 기록")
                                .font(.subheadline)
                        }
                    }
                    .tint(Color(hex: "8B5CF6"))
                    .padding(14)

                    if showStartDate {
                        Divider().padding(.leading, 56)
                        DatePicker("시작일", selection: $startedAt, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .environment(\.locale, Locale(identifier: "ko_KR"))
                            .padding(14)
                    }
                }

                Divider().padding(.leading, 56)

                // Finish date
                VStack(spacing: 0) {
                    Toggle(isOn: $showFinishDate) {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "3B82F6").opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(hex: "3B82F6"))
                            }
                            Text("완료일 기록")
                                .font(.subheadline)
                        }
                    }
                    .tint(Color(hex: "8B5CF6"))
                    .padding(14)

                    if showFinishDate {
                        Divider().padding(.leading, 56)
                        DatePicker("완료일", selection: $finishedAt, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .environment(\.locale, Locale(identifier: "ko_KR"))
                            .padding(14)
                    }
                }
            }
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: colorScheme == .dark ? .black.opacity(0.25) : .black.opacity(0.05), radius: 8, x: 0, y: 3)
        }
    }

    // MARK: - Review Section

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("감상평", icon: "quote.bubble.fill", color: Color(hex: "8B5CF6"))

            NavigationLink {
                RichReviewEditor(blocks: $richBlocks)
                    .navigationTitle("감상평 작성")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        AppTheme.primaryGradient
                        Image(systemName: "pencil.and.scribble")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(richBlocks.isEmpty ? "감상평 작성하기" : "감상평 수정하기")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        Text(richBlocks.isEmpty
                             ? "사진, 인용구, 제목 블록을 추가할 수 있어요"
                             : "\(richBlocks.count)개 블록 작성됨")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding(14)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: colorScheme == .dark ? .black.opacity(0.25) : .black.opacity(0.05), radius: 8, x: 0, y: 3)
            }
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("태그", icon: "tag.fill", color: Color(hex: "F59E0B"))

            VStack(spacing: 12) {
                // Selected tags
                if !selectedTags.isEmpty {
                    FlowLayout(spacing: 7) {
                        ForEach(selectedTags, id: \.self) { tag in
                            HStack(spacing: 5) {
                                Text("#\(tag)")
                                    .font(.caption.weight(.semibold))
                                Button {
                                    withAnimation { selectedTags.removeAll { $0 == tag } }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 12))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(hex: "8B5CF6").opacity(0.12))
                            .foregroundColor(Color(hex: "8B5CF6"))
                            .clipShape(Capsule())
                        }
                    }
                }

                // Tag input
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "number")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "8B5CF6"))
                        TextField("태그 입력", text: $tagInput)
                            .font(.subheadline)
                            .submitLabel(.done)
                            .onSubmit { addTagFromInput() }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: colorScheme == .dark ? .black.opacity(0.2) : .black.opacity(0.05), radius: 6, x: 0, y: 2)

                    Button { addTagFromInput() } label: {
                        Text("추가")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                            .background(
                                Group {
                                    if tagInput.trimmingCharacters(in: .whitespaces).isEmpty {
                                        AnyView(Color(.systemGray4))
                                    } else {
                                        AnyView(AppTheme.primaryGradient)
                                    }
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                // Keyword suggestions
                if !suggestedKeywords.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 5) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.yellow)
                            Text("추천 키워드")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                        }

                        FlowLayout(spacing: 7) {
                            ForEach(suggestedKeywords.prefix(20), id: \.self) { keyword in
                                Button {
                                    withAnimation {
                                        if !selectedTags.contains(keyword) {
                                            selectedTags.append(keyword)
                                        }
                                    }
                                } label: {
                                    Text("#\(keyword)")
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color(.systemGray5))
                                        .foregroundColor(.secondary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Section Label

    private func sectionLabel(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
            }
            Text(title)
                .font(.headline.weight(.bold))
        }
    }

    // MARK: - Actions

    private func addTagFromInput() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !selectedTags.contains(trimmed) else { return }
        selectedTags.append(trimmed)
        tagInput = ""
    }

    private func saveWork() {
        isSaving = true

        let work = Work(
            title: searchResult.title,
            type: searchResult.type,
            year: searchResult.year,
            genre: searchResult.genre,
            author: searchResult.author,
            posterURL: searchResult.posterURL,
            workDescription: searchResult.description,
            platform: searchResult.platform,
            externalID: searchResult.externalID
        )

        let review = Review(
            rating: rating > 0 ? rating : nil,
            status: status,
            content: nil,
            startedAt: showStartDate ? startedAt : nil,
            finishedAt: showFinishDate ? finishedAt : nil,
            tags: selectedTags
        )
        if !richBlocks.isEmpty {
            review.richBlocks = richBlocks
        }

        work.review = review
        review.work = work

        modelContext.insert(work)
        modelContext.insert(review)

        try? modelContext.save()

        isSaving = false
        onSaved?()
        dismiss()
    }
}

// MARK: - FlowLayout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxY: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxY = currentY + lineHeight
        }

        return CGSize(width: width, height: maxY)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
    }
}
