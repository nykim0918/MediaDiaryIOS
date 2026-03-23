//
//  LibraryView.swift
//  MediaDiary
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Work.createdAt, order: .reverse) private var allWorks: [Work]

    @State private var keywordInput: String = ""
    @State private var activeKeywords: [String] = []
    @State private var selectedType: String = "all"
    @State private var selectedStatus: String = "all"
    @State private var sortOrder: String = "recent"
    @State private var isGridView: Bool = true

    private let types: [(String, String, String)] = [
        ("all", "전체", "square.grid.2x2"),
        ("movie", "영화", "movieclapper.fill"),
        ("drama", "드라마", "tv.fill"),
        ("anime", "애니", "sparkles.tv.fill"),
        ("novel", "소설", "character.book.closed.fill"),
        ("webtoon", "웹툰", "rectangle.stack.fill")
    ]

    private let statuses: [(String, String, String)] = [
        ("all", "전체", "square.stack.fill"),
        ("completed", "완료", "checkmark.seal.fill"),
        ("in_progress", "보는 중", "play.circle.fill"),
        ("want", "보고 싶어요", "heart.circle.fill"),
        ("dropped", "그만봤어요", "xmark.circle.fill")
    ]

    private let gridColumns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    private var filteredWorks: [Work] {
        var result = allWorks

        if selectedType != "all" {
            result = result.filter { $0.type == selectedType }
        }
        if selectedStatus != "all" {
            result = result.filter { $0.review?.status == selectedStatus }
        }
        if !activeKeywords.isEmpty {
            result = result.filter { work in
                activeKeywords.allSatisfy { kw in
                    let lk = kw.lowercased()
                    if work.title.lowercased().contains(lk) { return true }
                    if let genre = work.genre, genre.lowercased().contains(lk) { return true }
                    if let author = work.author, author.lowercased().contains(lk) { return true }
                    if let tags = work.review?.tags, tags.contains(where: { $0.lowercased().contains(lk) }) { return true }
                    return false
                }
            }
        }
        if sortOrder == "rating" {
            result = result.sorted { ($0.review?.rating ?? 0) > ($1.review?.rating ?? 0) }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                // Keyword chips
                if !activeKeywords.isEmpty {
                    keywordChips
                        .padding(.bottom, 6)
                }

                // Type filter
                filterBar(items: types, selected: $selectedType, useTypeColor: true)
                    .padding(.bottom, 2)

                // Status filter
                filterBar(items: statuses, selected: $selectedStatus, useTypeColor: false)
                    .padding(.bottom, 2)

                // Sort + view toggle bar
                sortToggleBar

                Divider()

                // Content
                if filteredWorks.isEmpty {
                    emptyView
                } else if isGridView {
                    gridView
                } else {
                    listView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("라이브러리")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "8B5CF6"))

                TextField("키워드 검색 (엔터로 추가)", text: $keywordInput)
                    .font(.subheadline)
                    .submitLabel(.search)
                    .onSubmit { addKeyword() }

                if !keywordInput.isEmpty {
                    Button { keywordInput = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        !keywordInput.isEmpty ? Color(hex: "8B5CF6").opacity(0.4) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .shadow(color: colorScheme == .dark ? .black.opacity(0.2) : .black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }

    // MARK: - Keyword Chips

    private var keywordChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(activeKeywords, id: \.self) { kw in
                    HStack(spacing: 5) {
                        Text("#\(kw)")
                            .font(.caption.weight(.semibold))
                        Button { activeKeywords.removeAll { $0 == kw } } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "8B5CF6").opacity(0.15), Color(hex: "6366F1").opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(Color(hex: "8B5CF6"))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color(hex: "8B5CF6").opacity(0.2), lineWidth: 0.5))
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeKeywords = []
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 11))
                        Text("전체 해제")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Filter Bar

    private func filterBar(items: [(String, String, String)], selected: Binding<String>, useTypeColor: Bool) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.0) { value, label, icon in
                    let isSelected = selected.wrappedValue == value
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selected.wrappedValue = value
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(label)
                                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 8)
                        .background(
                            Group {
                                if isSelected {
                                    if useTypeColor && value != "all" {
                                        AnyView(AppTheme.typeGradient(value))
                                    } else {
                                        AnyView(AppTheme.primaryGradient)
                                    }
                                } else {
                                    AnyView(AppTheme.surface)
                                }
                            }
                        )
                        .foregroundColor(isSelected ? .white : .secondary)
                        .clipShape(Capsule())
                        .shadow(
                            color: isSelected ? .black.opacity(0.2) : .clear,
                            radius: 6, x: 0, y: 3
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Sort Toggle

    private var sortToggleBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 5) {
                Image(systemName: "photo.stack.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("총 \(filteredWorks.count)개")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Menu {
                Button { sortOrder = "recent" } label: {
                    Label("최근순", systemImage: sortOrder == "recent" ? "checkmark" : "clock")
                }
                Button { sortOrder = "rating" } label: {
                    Label("별점순", systemImage: sortOrder == "rating" ? "checkmark" : "star")
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 11, weight: .semibold))
                    Text(sortOrder == "recent" ? "최근순" : "별점순")
                        .font(.caption.weight(.semibold))
                }
                .foregroundColor(Color(hex: "8B5CF6"))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color(hex: "8B5CF6").opacity(0.1))
                .clipShape(Capsule())
            }

            // View toggle
            HStack(spacing: 1) {
                Button { withAnimation { isGridView = true } } label: {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isGridView ? .white : Color(.tertiaryLabel))
                        .frame(width: 32, height: 28)
                        .background(isGridView ? AnyView(AppTheme.primaryGradient) : AnyView(Color.clear))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                Button { withAnimation { isGridView = false } } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(!isGridView ? .white : Color(.tertiaryLabel))
                        .frame(width: 32, height: 28)
                        .background(!isGridView ? AnyView(AppTheme.primaryGradient) : AnyView(Color.clear))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
            }
            .padding(2)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: colorScheme == .dark ? .black.opacity(0.2) : .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Grid View

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(filteredWorks) { work in
                    NavigationLink(destination: DetailView(work: work)) {
                        WorkCardView(work: work)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }

    // MARK: - List View

    private var listView: some View {
        List {
            ForEach(filteredWorks) { work in
                NavigationLink(destination: DetailView(work: work)) {
                    WorkRowView(work: work)
                }
                .listRowBackground(AppTheme.surface)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) { deleteWork(work) } label: {
                        Label("삭제", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 100, height: 100)
                Image(systemName: "tray.fill")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(Color(.systemGray3))
            }

            VStack(spacing: 8) {
                Text("작품이 없어요")
                    .font(.headline.weight(.bold))
                if !activeKeywords.isEmpty || selectedType != "all" || selectedStatus != "all" {
                    Text("필터 조건에 맞는 작품이 없어요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button {
                        withAnimation {
                            activeKeywords = []
                            selectedType = "all"
                            selectedStatus = "all"
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                            Text("필터 초기화")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(hex: "8B5CF6"))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color(hex: "8B5CF6").opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Helpers

    private func addKeyword() {
        let trimmed = keywordInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !activeKeywords.contains(trimmed) else {
            keywordInput = ""
            return
        }
        withAnimation {
            activeKeywords.append(trimmed)
        }
        keywordInput = ""
    }

    private func deleteWork(_ work: Work) {
        modelContext.delete(work)
        try? modelContext.save()
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: [Work.self, Review.self], inMemory: true)
}
