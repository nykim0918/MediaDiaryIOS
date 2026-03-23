//
//  ContentView.swift
//  MediaDiary
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @Environment(\.colorScheme) private var colorScheme

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.shadowColor = UIColor.separator

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("홈", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)

            SearchView()
                .tabItem {
                    Label("검색", systemImage: selectedTab == 1 ? "sparkle.magnifyingglass" : "magnifyingglass")
                }
                .tag(1)

            CalendarView()
                .tabItem {
                    Label("캘린더", systemImage: selectedTab == 2 ? "calendar.badge.clock" : "calendar")
                }
                .tag(2)

            LibraryView()
                .tabItem {
                    Label("라이브러리", systemImage: selectedTab == 3 ? "books.vertical.fill" : "books.vertical")
                }
                .tag(3)
        }
        .tint(Color(hex: "8B5CF6"))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Work.self, Review.self], inMemory: true)
}
