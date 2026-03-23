//
//  CalendarView.swift
//  MediaDiary
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Work.createdAt, order: .reverse) private var works: [Work]

    @State private var displayedMonth: Date = {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: Date())
        return cal.date(from: comps) ?? Date()
    }()
    @State private var selectedDate: Date? = nil
    @State private var selectedWork: Work? = nil

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdayLabels = ["일", "월", "화", "수", "목", "금", "토"]

    // MARK: - Date helpers

    private var monthTitle: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "yyyy년 M월"
        return fmt.string(from: displayedMonth)
    }

    private var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let first = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let weekday = (calendar.component(.weekday, from: first) - 1 + 7) % 7 // 0=Sun
        var days: [Date?] = Array(repeating: nil, count: weekday)
        for day in range {
            days.append(calendar.date(byAdding: .day, value: day - 1, to: first))
        }
        // pad to complete last row
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    /// Map: date-string → [Work] (using createdAt)
    private var worksByDate: [String: [Work]] {
        var map: [String: [Work]] = [:]
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        for work in works {
            let key = fmt.string(from: work.createdAt)
            map[key, default: []].append(work)
        }
        return map
    }

    private func dateKey(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    private func isSelected(_ date: Date) -> Bool {
        guard let sel = selectedDate else { return false }
        return calendar.isDate(date, inSameDayAs: sel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    calendarHeader
                    monthGrid
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)

                    if let date = selectedDate {
                        selectedDaySection(for: date)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("캘린더")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedWork) { work in
                DetailView(work: work)
            }
        }
    }

    // MARK: - Calendar Header

    private var calendarHeader: some View {
        VStack(spacing: 0) {
            // Month navigator
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                        selectedDate = nil
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "8B5CF6"))
                        .frame(width: 36, height: 36)
                        .background(Color(hex: "8B5CF6").opacity(0.1))
                        .clipShape(Circle())
                }

                Spacer()

                Text(monthTitle)
                    .font(.title3.weight(.bold))

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                        selectedDate = nil
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "8B5CF6"))
                        .frame(width: 36, height: 36)
                        .background(Color(hex: "8B5CF6").opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Weekday labels
            HStack(spacing: 0) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(label == "일" ? .red.opacity(0.7) : label == "토" ? Color(hex: "6366F1") : .secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            Divider()
        }
        .background(AppTheme.surface)
    }

    // MARK: - Month Grid

    private var monthGrid: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                if let date {
                    DayCell(
                        date: date,
                        works: worksByDate[dateKey(date)] ?? [],
                        isToday: isToday(date),
                        isSelected: isSelected(date),
                        weekdayIndex: (calendar.component(.weekday, from: date) - 1 + 7) % 7
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            if let sel = selectedDate, calendar.isDate(sel, inSameDayAs: date) {
                                selectedDate = nil
                            } else {
                                selectedDate = date
                            }
                        }
                    }
                } else {
                    Color.clear
                        .frame(height: dayCellHeight)
                }
            }
        }
        .padding(.top, 8)
    }

    private var dayCellHeight: CGFloat { 72 }

    // MARK: - Selected Day Section

    @ViewBuilder
    private func selectedDaySection(for date: Date) -> some View {
        let dayWorks = worksByDate[dateKey(date)] ?? []
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(AppTheme.primaryGradient)
                        .frame(width: 26, height: 26)
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                let fmt: DateFormatter = {
                    let f = DateFormatter()
                    f.locale = Locale(identifier: "ko_KR")
                    f.dateFormat = "M월 d일 EEEE"
                    return f
                }()
                Text(fmt.string(from: date))
                    .font(.headline.weight(.bold))
                if dayWorks.isEmpty {
                    Text("기록 없음")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if dayWorks.isEmpty {
                Text("이 날은 기록된 작품이 없어요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(dayWorks) { work in
                    Button {
                        selectedWork = work
                    } label: {
                        HStack(spacing: 14) {
                            PosterImageView(urlString: work.posterURL, height: 64, type: work.type)
                                .frame(width: 44, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)

                            VStack(alignment: .leading, spacing: 5) {
                                TypeBadgeView(type: work.type, small: true)
                                Text(work.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                if let rating = work.review?.rating, rating > 0 {
                                    HStack(spacing: 3) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.yellow)
                                        Text(String(format: "%.1f", rating))
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                        .padding(12)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: colorScheme == .dark ? .black.opacity(0.25) : .black.opacity(0.06), radius: 8, x: 0, y: 3)
                    }
                }
            }
        }
    }
}

// MARK: - DayCell

struct DayCell: View {
    let date: Date
    let works: [Work]
    let isToday: Bool
    let isSelected: Bool
    let weekdayIndex: Int  // 0=Sun … 6=Sat

    @Environment(\.colorScheme) private var colorScheme
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 2) {
            // Day number
            ZStack {
                if isSelected {
                    Circle()
                        .fill(AppTheme.primaryGradient)
                        .frame(width: 28, height: 28)
                } else if isToday {
                    Circle()
                        .stroke(Color(hex: "8B5CF6"), lineWidth: 1.5)
                        .frame(width: 28, height: 28)
                }

                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 13, weight: isToday || isSelected ? .bold : .regular))
                    .foregroundColor(
                        isSelected ? .white :
                        isToday ? Color(hex: "8B5CF6") :
                        weekdayIndex == 0 ? .red.opacity(0.8) :
                        weekdayIndex == 6 ? Color(hex: "6366F1") :
                        .primary
                    )
            }
            .frame(height: 30)

            // Poster thumbnails (up to 3)
            if !works.isEmpty {
                posterThumbnail
            } else {
                Spacer()
            }
        }
        .frame(height: 72)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected
                      ? Color(hex: "8B5CF6").opacity(0.06)
                      : Color.clear)
        )
    }

    @ViewBuilder
    private var posterThumbnail: some View {
        if works.count == 1, let work = works.first {
            // Single work: show poster
            PosterImageView(urlString: work.posterURL, height: 36, type: work.type)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .padding(.horizontal, 3)
        } else {
            // Multiple: show up to 2 posters side-by-side + count badge
            HStack(spacing: 2) {
                ForEach(works.prefix(2)) { work in
                    PosterImageView(urlString: work.posterURL, height: 36, type: work.type)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                }
            }
            .padding(.horizontal, 2)
            .overlay(alignment: .bottomTrailing) {
                if works.count > 2 {
                    Text("+\(works.count - 2)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color(hex: "8B5CF6"))
                        .clipShape(Capsule())
                        .offset(x: -4, y: -4)
                }
            }
        }
    }
}
