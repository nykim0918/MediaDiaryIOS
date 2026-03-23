//
//  SearchView.swift
//  MediaDiary
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedType = "movie"
    @State private var searchQuery = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var selectedResult: SearchResult?
    @State private var showAddSheet = false
    @State private var showManualEntry = false

    private let types: [(id: String, label: String, icon: String)] = [
        ("movie",   "영화",   "movieclapper.fill"),
        ("drama",   "드라마",  "tv.fill"),
        ("anime",   "애니",   "sparkles.tv.fill"),
        ("novel",   "소설",   "character.book.closed.fill"),
        ("game",    "게임",   "gamecontroller.fill"),
        ("webtoon", "웹툰",   "rectangle.stack.fill")
    ]

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    private var isManualOnlyType: Bool {
        selectedType == "webtoon" || selectedType == "game"
    }

    private var searchPlaceholder: String {
        switch selectedType {
        case "movie":  return "영화 제목을 입력하세요"
        case "drama":  return "드라마 제목을 입력하세요"
        case "anime":  return "애니 제목 (한국어·영어·일본어)"
        case "novel":  return "소설 제목 또는 작가명"
        default:       return "제목을 입력하세요"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Compact horizontal type selector (키보드 겹침 방지)
                typeSelector
                    .padding(.top, 4)

                // Search bar (manual-only 타입 제외)
                if !isManualOnlyType {
                    searchBar
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                }

                Divider()

                // Content area
                contentArea
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("작품 검색")
            .navigationBarTitleDisplayMode(.inline)   // inline으로 고정 (키보드 겹침 방지)
            .sheet(isPresented: $showAddSheet) {
                if let result = selectedResult {
                    AddReviewSheet(searchResult: result)
                }
            }
            .sheet(isPresented: $showManualEntry) {
                ManualEntrySheet(defaultType: selectedType)
            }
        }
    }

    // MARK: - Type Selector (Compact Capsule Style)

    private var typeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(types, id: \.id) { typeItem in
                    let isSelected = selectedType == typeItem.id

                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedType = typeItem.id
                            searchQuery = ""
                            searchResults = []
                            searchError = nil
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: typeItem.icon)
                                .font(.system(size: 12, weight: .bold))
                            Text(typeItem.label)
                                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            isSelected
                                ? AnyView(AppTheme.typeGradient(typeItem.id))
                                : AnyView(AppTheme.surface)
                        )
                        .foregroundColor(isSelected ? .white : .secondary)
                        .clipShape(Capsule())
                        .shadow(
                            color: isSelected ? AppTheme.typeColor(typeItem.id).opacity(0.35) : .clear,
                            radius: 5, x: 0, y: 3
                        )
                    }
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.typeColor(selectedType))

                TextField(searchPlaceholder, text: $searchQuery)
                    .font(.subheadline)
                    .submitLabel(.search)
                    .onSubmit { performSearch() }

                if !searchQuery.isEmpty {
                    Button { searchQuery = "" } label: {
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
                        !searchQuery.isEmpty ? AppTheme.typeColor(selectedType).opacity(0.4) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .shadow(color: colorScheme == .dark ? .black.opacity(0.2) : .black.opacity(0.05), radius: 6, x: 0, y: 2)

            // 검색 버튼
            Button { performSearch() } label: {
                ZStack {
                    AppTheme.typeGradient(selectedType)
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: AppTheme.typeColor(selectedType).opacity(0.35), radius: 6, x: 0, y: 3)
            }

            // 직접입력 버튼
            Button { showManualEntry = true } label: {
                ZStack {
                    Color(hex: "8B5CF6").opacity(0.12)
                    Image(systemName: "pencil")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "8B5CF6"))
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentArea: some View {
        if selectedType == "webtoon" {
            manualOnlyPrompt(
                icon: "rectangle.stack.fill",
                type: "webtoon",
                title: "웹툰 직접 입력",
                description: "웹툰은 직접 정보를 입력해서\n기록할 수 있어요",
                buttonLabel: "웹툰 추가하기"
            )
        } else if selectedType == "game" {
            manualOnlyPrompt(
                icon: "gamecontroller.fill",
                type: "game",
                title: "게임 직접 입력",
                description: "게임 정보를 직접 입력해서\n기록할 수 있어요",
                buttonLabel: "게임 추가하기"
            )
        } else if isSearching {
            loadingView
        } else if let error = searchError {
            errorView(error)
        } else if !searchResults.isEmpty {
            resultsGrid
        } else if !searchQuery.isEmpty {
            noResultsView
        } else {
            placeholderView
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.typeColor(selectedType).opacity(0.1))
                    .frame(width: 80, height: 80)
                ProgressView()
                    .scaleEffect(1.4)
                    .tint(AppTheme.typeColor(selectedType))
            }
            Text(selectedType == "anime" ? "AniList + MAL 검색 중..." : "검색 중...")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.keyboard)
    }

    private var placeholderView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AppTheme.typeColor(selectedType).opacity(0.1))
                    .frame(width: 110, height: 110)
                Circle()
                    .fill(AppTheme.typeColor(selectedType).opacity(0.06))
                    .frame(width: 80, height: 80)
                Image(systemName: AppTheme.typeIcon(selectedType))
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(AppTheme.typeGradient(selectedType))
            }

            VStack(spacing: 8) {
                Text("\(AppTheme.typeLabel(selectedType)) 검색")
                    .font(.title3.weight(.bold))
                if selectedType == "anime" {
                    Text("한국어·영어·일본어 제목으로 검색 가능")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("제목을 입력하고 검색해보세요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Button { showManualEntry = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 15))
                    Text("직접 입력하기")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color(hex: "8B5CF6"))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(hex: "8B5CF6").opacity(0.1))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(hex: "8B5CF6").opacity(0.2), lineWidth: 1))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .ignoresSafeArea(.keyboard)
    }

    private var noResultsView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 100, height: 100)
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 42, weight: .light))
                    .foregroundColor(Color(.systemGray3))
            }
            Text("'\(searchQuery)'에 대한 결과가 없어요")
                .font(.headline.weight(.bold))
                .multilineTextAlignment(.center)
            if selectedType == "anime" {
                Text("한국어, 영어, 일본어 제목으로 다시 시도해보세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("다른 검색어로 시도하거나 직접 입력해보세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button { showManualEntry = true } label: {
                HStack(spacing: 5) {
                    Image(systemName: "pencil.circle.fill")
                    Text("직접 입력하기")
                }
                .primaryButton()
                .frame(width: 180)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .ignoresSafeArea(.keyboard)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
            }
            Text("검색 오류")
                .font(.headline.weight(.bold))
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button { performSearch() } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                    Text("다시 시도")
                }
                .primaryButton()
                .frame(width: 160)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .ignoresSafeArea(.keyboard)
    }

    private func manualOnlyPrompt(
        icon: String, type: String, title: String, description: String, buttonLabel: String
    ) -> some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(AppTheme.typeColor(type).opacity(0.12))
                    .frame(width: 130, height: 130)
                Circle()
                    .fill(AppTheme.typeColor(type).opacity(0.07))
                    .frame(width: 95, height: 95)
                Image(systemName: icon)
                    .font(.system(size: 46, weight: .light))
                    .foregroundStyle(AppTheme.typeGradient(type))
            }

            VStack(spacing: 10) {
                Text(title)
                    .font(.title3.weight(.bold))
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button { showManualEntry = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text(buttonLabel)
                }
                .primaryButton()
                .frame(width: 210)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Results Grid

    private var resultsGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.typeColor(selectedType))
                        Text("검색 결과 \(searchResults.count)개")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button { showManualEntry = true } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.system(size: 11))
                            Text("직접 입력")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(Color(hex: "8B5CF6"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: "8B5CF6").opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(searchResults) { result in
                        SearchResultCard(result: result) {
                            selectedResult = result
                            showAddSheet = true
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Actions

    private func performSearch() {
        let q = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }

        isSearching = true
        searchError = nil
        searchResults = []

        Task {
            do {
                let results: [SearchResult]
                switch selectedType {
                case "movie", "drama":
                    results = try await SearchService.shared.searchTMDB(query: q, type: selectedType)
                case "anime":
                    results = try await SearchService.shared.searchAnime(query: q)
                case "novel", "webtoon":
                    results = try await SearchService.shared.searchBooks(query: q, type: selectedType)
                default:
                    results = []
                }
                searchResults = results
                isSearching = false
            } catch let error as SearchError {
                searchError = error.localizedDescription
                isSearching = false
            } catch {
                searchError = error.localizedDescription
                isSearching = false
            }
        }
    }
}

// MARK: - SearchResultCard

struct SearchResultCard: View {
    let result: SearchResult
    let onAdd: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Poster
            ZStack(alignment: .top) {
                PosterImageView(urlString: result.posterURL, height: 180, type: result.type)
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipped()

                LinearGradient(
                    colors: [.black.opacity(0.3), .clear],
                    startPoint: .top, endPoint: .center
                )

                HStack {
                    TypeBadgeView(type: result.type, small: true, onPoster: true)
                    Spacer()
                    if let year = result.year {
                        Text(year)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
                .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(result.title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Button { onAdd() } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 13))
                        Text("추가하기")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(AppTheme.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: Color(hex: "8B5CF6").opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
            .padding(10)
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(
            color: colorScheme == .dark ? .black.opacity(0.35) : .black.opacity(0.1),
            radius: 10, x: 0, y: 4
        )
    }
}

// MARK: - ManualEntrySheet

struct ManualEntrySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var defaultType: String = "movie"

    @State private var title = ""
    @State private var type: String
    @State private var year = ""
    @State private var genre = ""
    @State private var author = ""
    @State private var platform = ""
    @State private var description = ""

    @State private var rating: Double = 0
    @State private var status = "want"
    @State private var richBlocks: [ReviewBlock] = []
    @State private var startedAt = Date()
    @State private var finishedAt = Date()
    @State private var showStartDate = false
    @State private var showFinishDate = false
    @State private var tagInput = ""
    @State private var selectedTags: [String] = []
    @State private var isSaving = false
    @State private var showTitleError = false
    @State private var showRichEditor = false

    private let types: [(String, String)] = [
        ("movie", "영화"), ("drama", "드라마"), ("anime", "애니"),
        ("novel", "소설"), ("game", "게임"), ("webtoon", "웹툰")
    ]
    private let statuses = [
        ("completed", "완료"), ("in_progress", "보는 중"),
        ("want", "보고 싶어요"), ("dropped", "그만봤어요")
    ]

    init(defaultType: String = "movie") {
        self.defaultType = defaultType
        _type = State(initialValue: defaultType)
    }

    private var suggestedKeywords: [String] {
        KeywordService.shared.keywords(for: type, genre: genre.isEmpty ? nil : genre)
            .filter { !selectedTags.contains($0) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("제목 *", text: $title)
                    Picker("종류", selection: $type) {
                        ForEach(types, id: \.0) { Text($1).tag($0) }
                    }
                    TextField("연도 (예: 2024)", text: $year).keyboardType(.numberPad)
                    TextField("장르 (예: 로맨스, 판타지)", text: $genre)
                    TextField("작가 / 감독 / 개발사", text: $author)
                    TextField("플랫폼 (예: 넷플릭스, Steam)", text: $platform)
                    TextField("설명", text: $description, axis: .vertical).lineLimit(3...6)
                } header: {
                    Label("작품 정보", systemImage: AppTheme.typeIcon(type))
                }

                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("평점").font(.subheadline.weight(.medium))
                        HStack {
                            StarRatingView(rating: $rating, isEditable: true, starSize: 32)
                            Spacer()
                            Text(rating > 0 ? String(format: "%.1f", rating) : "미평가")
                                .font(.headline)
                                .foregroundColor(rating > 0 ? .primary : .secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    Picker("상태", selection: $status) {
                        ForEach(statuses, id: \.0) { Text($1).tag($0) }
                    }

                    Toggle("시작일 기록", isOn: $showStartDate).tint(Color(hex: "8B5CF6"))
                    if showStartDate {
                        DatePicker("시작일", selection: $startedAt, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "ko_KR"))
                    }
                    Toggle("완료일 기록", isOn: $showFinishDate).tint(Color(hex: "8B5CF6"))
                    if showFinishDate {
                        DatePicker("완료일", selection: $finishedAt, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "ko_KR"))
                    }
                } header: {
                    Label("감상 기록", systemImage: "star.bubble.fill")
                }

                Section {
                    NavigationLink {
                        richEditorPage
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color(hex: "8B5CF6").opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "pencil.and.scribble")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "8B5CF6"))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("감상평 작성")
                                    .font(.subheadline.weight(.semibold))
                                Text(richBlocks.isEmpty ? "사진, 인용구, 제목 블록으로 꾸미기" : "\(richBlocks.count)개 블록 작성됨")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Label("감상평 (리치 에디터)", systemImage: "doc.richtext.fill")
                }

                Section {
                    if !selectedTags.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(selectedTags, id: \.self) { tag in
                                HStack(spacing: 3) {
                                    Text("#\(tag)").font(.caption.weight(.semibold))
                                    Button { selectedTags.removeAll { $0 == tag } } label: {
                                        Image(systemName: "xmark.circle.fill").font(.system(size: 12))
                                    }
                                }
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Color(hex: "8B5CF6").opacity(0.12))
                                .foregroundColor(Color(hex: "8B5CF6"))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    HStack {
                        TextField("태그 입력", text: $tagInput).submitLabel(.done).onSubmit { addTag() }
                        Button("추가") { addTag() }
                            .disabled(tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
                            .foregroundColor(Color(hex: "8B5CF6"))
                    }
                    if !suggestedKeywords.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(suggestedKeywords.prefix(20), id: \.self) { kw in
                                Button {
                                    if !selectedTags.contains(kw) { selectedTags.append(kw) }
                                } label: {
                                    Text("#\(kw)").font(.caption)
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Color(.systemGray5))
                                        .foregroundColor(.secondary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Label("태그", systemImage: "tag.fill")
                }
            }
            .navigationTitle("직접 입력")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        if title.trimmingCharacters(in: .whitespaces).isEmpty {
                            showTitleError = true
                        } else { save() }
                    }
                    .fontWeight(.semibold)
                    .disabled(isSaving)
                }
            }
            .alert("제목을 입력해 주세요", isPresented: $showTitleError) {
                Button("확인", role: .cancel) {}
            }
        }
    }

    // MARK: - Rich Editor Page

    private var richEditorPage: some View {
        VStack(spacing: 0) {
            RichReviewEditor(blocks: $richBlocks)
        }
        .navigationTitle("감상평 작성")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }

    private func addTag() {
        let t = tagInput.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, !selectedTags.contains(t) else { return }
        selectedTags.append(t); tagInput = ""
    }

    private func save() {
        isSaving = true
        let work = Work(
            title: title.trimmingCharacters(in: .whitespaces), type: type,
            year: year.isEmpty ? nil : year,
            genre: genre.isEmpty ? nil : genre,
            author: author.isEmpty ? nil : author,
            workDescription: description.isEmpty ? nil : description,
            platform: platform.isEmpty ? nil : platform
        )
        let review = Review(
            rating: rating > 0 ? rating : nil, status: status,
            startedAt: showStartDate ? startedAt : nil,
            finishedAt: showFinishDate ? finishedAt : nil,
            tags: selectedTags
        )
        review.richBlocks = richBlocks
        work.review = review; review.work = work
        modelContext.insert(work); modelContext.insert(review)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    SearchView()
        .modelContainer(for: [Work.self, Review.self], inMemory: true)
}
