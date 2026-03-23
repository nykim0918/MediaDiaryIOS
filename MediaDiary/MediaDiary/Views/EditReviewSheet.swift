//
//  EditReviewSheet.swift
//  MediaDiary
//

import SwiftUI
import SwiftData

struct EditReviewSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let work: Work
    var onSaved: (() -> Void)?

    @State private var rating: Double
    @State private var status: String
    @State private var reviewContent: String
    @State private var startedAt: Date
    @State private var finishedAt: Date
    @State private var showStartDate: Bool
    @State private var showFinishDate: Bool
    @State private var tagInput: String = ""
    @State private var selectedTags: [String]
    @State private var richBlocks: [ReviewBlock]
    @State private var isSaving: Bool = false

    private let statuses = [
        ("completed", "완료", "checkmark.seal.fill"),
        ("in_progress", "보는 중", "play.circle.fill"),
        ("want", "보고 싶어요", "heart.circle.fill"),
        ("dropped", "그만봤어요", "xmark.circle.fill")
    ]

    init(work: Work, onSaved: (() -> Void)? = nil) {
        self.work = work
        self.onSaved = onSaved
        let review = work.review
        _rating = State(initialValue: review?.rating ?? 0)
        _status = State(initialValue: review?.status ?? "want")
        _reviewContent = State(initialValue: review?.content ?? "")
        _startedAt = State(initialValue: review?.startedAt ?? Date())
        _finishedAt = State(initialValue: review?.finishedAt ?? Date())
        _showStartDate = State(initialValue: review?.startedAt != nil)
        _showFinishDate = State(initialValue: review?.finishedAt != nil)
        _selectedTags = State(initialValue: review?.tags ?? [])
        _richBlocks = State(initialValue: review?.richBlocks ?? [])
    }

    private var suggestedKeywords: [String] {
        KeywordService.shared.keywords(for: work.type, genre: work.genre)
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
            .navigationTitle("리뷰 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장하기") { saveChanges() }
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
            AppTheme.typeGradient(work.type)
                .frame(height: 180)
                .overlay(Color.black.opacity(0.35))

            HStack(alignment: .bottom, spacing: 16) {
                PosterImageView(urlString: work.posterURL, height: 160, type: work.type)
                    .frame(width: 108, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    TypeBadgeView(type: work.type, onPoster: true)

                    Text(work.title)
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .lineLimit(3)

                    VStack(alignment: .leading, spacing: 3) {
                        if let year = work.year {
                            Label(year, systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.75))
                        }
                        if let genre = work.genre {
                            Label(genre, systemImage: "tag.fill")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.75))
                                .lineLimit(1)
                        }
                        if let author = work.author {
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
                    .navigationTitle("감상평 수정")
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

    private func saveChanges() {
        isSaving = true

        if let review = work.review {
            review.rating = rating > 0 ? rating : nil
            review.status = status
            review.content = nil
            review.startedAt = showStartDate ? startedAt : nil
            review.finishedAt = showFinishDate ? finishedAt : nil
            review.tags = selectedTags
            review.richBlocks = richBlocks
            review.updatedAt = Date()
        } else {
            let review = Review(
                rating: rating > 0 ? rating : nil,
                status: status,
                content: nil,
                startedAt: showStartDate ? startedAt : nil,
                finishedAt: showFinishDate ? finishedAt : nil,
                tags: selectedTags
            )
            review.richBlocks = richBlocks
            work.review = review
            review.work = work
            modelContext.insert(review)
        }

        try? modelContext.save()

        isSaving = false
        onSaved?()
        dismiss()
    }
}
