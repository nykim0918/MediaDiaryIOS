//
//  HomeView.swift
//  MediaDiary
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Work.createdAt, order: .reverse) private var works: [Work]
    @Binding var selectedTab: Int

    @State private var showSettings = false
    @State private var recommendations: [SearchResult] = []
    @State private var animateHero = false

    // MARK: Computed

    private var totalCount: Int { works.count }

    private var avgRating: Double {
        let rated = works.compactMap { $0.review?.rating }.filter { $0 > 0 }
        guard !rated.isEmpty else { return 0 }
        return rated.reduce(0, +) / Double(rated.count)
    }

    private var completedCount: Int { works.filter { $0.review?.status == "completed" }.count }
    private var inProgressCount: Int { works.filter { $0.review?.status == "in_progress" }.count }
    private var recentWorks: [Work] { Array(works.prefix(6)) }
    private let libraryTabIndex = 3

    private var typeBreakdown: [(type: String, count: Int)] {
        ["movie", "drama", "anime", "novel", "webtoon", "game"].compactMap { type in
            let count = works.filter { $0.type == type }.count
            return count > 0 ? (type, count) : nil
        }
    }

    private var topGenre: String? {
        var counts: [String: Int] = [:]
        for work in works {
            if let genre = work.genre {
                let main = genre.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? genre
                counts[main, default: 0] += 1
            }
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Hero
                    headerHero

                    if works.isEmpty {
                        emptyState
                            .padding(.top, 48)
                    } else {
                        VStack(spacing: 32) {
                            statsGrid
                                .padding(.horizontal)
                            typeBreakdownSection
                                .padding(.horizontal)
                            recentSection
                            if !recommendations.isEmpty {
                                recommendSection
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top, 28)
                        .padding(.bottom, 40)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) { SettingsView() }
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) { animateHero = true }
                fetchRecommendations()
            }
        }
    }

    // MARK: - Header Hero

    private var headerHero: some View {
        ZStack(alignment: .bottom) {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "6D28D9"), Color(hex: "4F46E5"), Color(hex: "2563EB")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 220)

            // Decorative orbs
            GeometryReader { geo in
                Circle()
                    .fill(.white.opacity(0.07))
                    .frame(width: 200, height: 200)
                    .offset(x: geo.size.width - 80, y: -60)
                    .scaleEffect(animateHero ? 1.0 : 0.8)
                    .animation(.easeOut(duration: 1.2), value: animateHero)

                Circle()
                    .fill(.white.opacity(0.05))
                    .frame(width: 130, height: 130)
                    .offset(x: geo.size.width - 40, y: 30)
                    .scaleEffect(animateHero ? 1.0 : 0.6)
                    .animation(.easeOut(duration: 1.4), value: animateHero)

                Circle()
                    .fill(.white.opacity(0.04))
                    .frame(width: 80, height: 80)
                    .offset(x: 30, y: -20)
                    .scaleEffect(animateHero ? 1.0 : 0.5)
                    .animation(.easeOut(duration: 1.0), value: animateHero)
            }
            .frame(height: 220)

            // Bottom fade
            LinearGradient(
                colors: [.clear, Color(.systemGroupedBackground).opacity(0.3)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 220)

            // Content
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    // App badge
                    HStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.2))
                                .frame(width: 36, height: 36)
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("MediaDiary")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .opacity(animateHero ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateHero)

                    Text("내 기록장")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(animateHero ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.3), value: animateHero)

                    Text("나만의 미디어 감상 일기")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.75))
                        .opacity(animateHero ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.4), value: animateHero)
                }
                .padding(.leading, 22)
                .padding(.bottom, 26)

                Spacer()

                Button {
                    showSettings = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.18))
                            .frame(width: 40, height: 40)
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 22)
                .padding(.bottom, 26)
                .opacity(animateHero ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.5), value: animateHero)
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("나의 기록 현황", icon: "chart.bar.fill")

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                StatCard2(
                    title: "전체 작품",
                    value: "\(totalCount)",
                    icon: "square.stack.3d.up.fill",
                    gradient: LinearGradient(colors: [Color(hex: "6D28D9"), Color(hex: "4F46E5")], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                StatCard2(
                    title: "평균 평점",
                    value: avgRating > 0 ? String(format: "%.1f ★", avgRating) : "—",
                    icon: "star.fill",
                    gradient: LinearGradient(colors: [Color(hex: "F59E0B"), Color(hex: "EF4444")], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                StatCard2(
                    title: "완료한 작품",
                    value: "\(completedCount)",
                    icon: "checkmark.seal.fill",
                    gradient: LinearGradient(colors: [Color(hex: "059669"), Color(hex: "10B981")], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                StatCard2(
                    title: "보는 중",
                    value: "\(inProgressCount)",
                    icon: "play.circle.fill",
                    gradient: LinearGradient(colors: [Color(hex: "0EA5E9"), Color(hex: "3B82F6")], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            }
        }
    }

    // MARK: - Type Breakdown

    private var typeBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("카테고리별", icon: "square.grid.2x2.fill")

            VStack(spacing: 0) {
                ForEach(Array(typeBreakdown.enumerated()), id: \.element.type) { index, item in
                    if index > 0 {
                        Divider()
                            .padding(.leading, 56)
                    }
                    HStack(spacing: 14) {
                        ZStack {
                            AppTheme.typeGradient(item.type)
                            Image(systemName: AppTheme.typeIcon(item.type))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: AppTheme.typeColor(item.type).opacity(0.3), radius: 4, x: 0, y: 2)

                        Text(AppTheme.typeLabel(item.type))
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)

                        Spacer()

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 6)
                                Capsule()
                                    .fill(AppTheme.typeGradient(item.type))
                                    .frame(
                                        width: geo.size.width * (totalCount > 0 ? Double(item.count) / Double(totalCount) : 0),
                                        height: 6
                                    )
                            }
                        }
                        .frame(width: 90, height: 6)

                        Text("\(item.count)")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.primary)
                            .frame(width: 28, alignment: .trailing)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.07), radius: 12, x: 0, y: 4)
        }
    }

    // MARK: - Recent Section

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionHeader("최근 추가", icon: "clock.fill")
                Spacer()
                Button {
                    selectedTab = libraryTabIndex
                } label: {
                    HStack(spacing: 3) {
                        Text("전체 보기")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(hex: "8B5CF6"))
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(recentWorks) { work in
                        NavigationLink(destination: DetailView(work: work)) {
                            RecentWorkCard(work: work)
                        }
                        .buttonStyle(.plain)
                    }

                    // 더 보기 card
                    Button { selectedTab = libraryTabIndex } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            ZStack {
                                LinearGradient(
                                    colors: [Color(hex: "8B5CF6").opacity(0.15), Color(hex: "6366F1").opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: "8B5CF6").opacity(0.15))
                                            .frame(width: 50, height: 50)
                                        Image(systemName: "chevron.right.2")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(AppTheme.primaryGradient)
                                    }
                                    Text("더 보기")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(Color(hex: "8B5CF6"))
                                }
                            }
                            .frame(width: 110, height: 155)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color(hex: "8B5CF6").opacity(0.2), lineWidth: 1.5)
                            )
                            // spacer text to match RecentWorkCard title height
                            Text(" ")
                                .font(.caption.weight(.semibold))
                                .lineLimit(2)
                                .opacity(0)
                        }
                        .frame(width: 110)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Recommend Section

    private var recommendSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let genre = topGenre {
                sectionHeader("'\(genre)' 장르 추천", icon: "wand.and.sparkles.tv.fill")
            } else {
                sectionHeader("추천 작품", icon: "wand.and.sparkles")
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(recommendations.prefix(4)) { result in
                    VStack(alignment: .leading, spacing: 8) {
                        PosterImageView(urlString: result.posterURL, height: 150, type: result.type)
                            .frame(maxWidth: .infinity)
                            .frame(height: 150)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)

                        Text(result.title)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)

                        if let year = result.year {
                            Text(year)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "8B5CF6").opacity(0.15), Color(hex: "6366F1").opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 130, height: 130)

                VStack(spacing: 4) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(AppTheme.primaryGradient)
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "8B5CF6").opacity(0.6))
                }
            }

            VStack(spacing: 10) {
                Text("아직 기록된 작품이 없어요")
                    .font(.title3.weight(.bold))
                Text("영화, 드라마, 소설 등 감상한 작품을\n지금 바로 기록해보세요!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button { selectedTab = 1 } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("새 작품 추가하기")
                }
                .primaryButton()
                .frame(width: 230)
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(AppTheme.primaryGradient)
                    .frame(width: 26, height: 26)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            Text(title)
                .font(.headline.weight(.bold))
        }
    }

    // MARK: - Actions

    private func fetchRecommendations() {
        guard !works.isEmpty, let genre = topGenre else { return }
        Task {
            if let results = try? await SearchService.shared.searchTMDB(query: genre, type: "movie") {
                recommendations = Array(results.prefix(4))
            }
        }
    }
}

// MARK: - StatCard2

struct StatCard2: View {
    let title: String
    let value: String
    let icon: String
    let gradient: LinearGradient
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                ZStack {
                    gradient
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 42, height: 42)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)

                Spacer()
            }
            .padding(.bottom, 14)

            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .padding(.bottom, 4)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .frame(height: 130)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(
            color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.07),
            radius: 12, x: 0, y: 4
        )
    }
}

// MARK: - RecentWorkCard

struct RecentWorkCard: View {
    let work: Work
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                PosterImageView(urlString: work.posterURL, height: 155, type: work.type)
                    .frame(width: 110, height: 155)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.5)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                if let rating = work.review?.rating, rating > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(7)
                }
            }
            .shadow(color: colorScheme == .dark ? .black.opacity(0.4) : .black.opacity(0.15), radius: 8, x: 0, y: 4)

            Text(work.title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(width: 110, alignment: .leading)

            TypeBadgeView(type: work.type, small: true)
        }
        .frame(width: 110)
    }
}

#Preview {
    HomeView(selectedTab: .constant(0))
        .modelContainer(for: [Work.self, Review.self], inMemory: true)
}
