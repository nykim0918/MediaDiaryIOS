//
//  SettingsView.swift
//  MediaDiary
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var tmdbAPIKey: String = UserDefaults.standard.string(forKey: "tmdb_api_key") ?? ""
    @State private var kakaoAPIKey: String = UserDefaults.standard.string(forKey: "kakao_api_key") ?? ""
    @State private var showSavedAlert: Bool = false
    @State private var showTMDBKey: Bool = false
    @State private var showKakaoKey: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    settingsHeader

                    // API Keys section
                    apiKeysSection

                    // Save button
                    Button { saveKeys() } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                            Text("API 키 저장")
                        }
                        .primaryButton()
                    }
                    .padding(.horizontal, 20)

                    // App info section
                    appInfoSection

                    Spacer(minLength: 20)
                }
                .padding(.vertical, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "8B5CF6"))
                }
            }
            .alert("저장 완료", isPresented: $showSavedAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("API 키가 저장되었습니다.")
            }
        }
    }

    // MARK: - Header

    private var settingsHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.primaryGradient)
                    .frame(width: 70, height: 70)
                    .shadow(color: Color(hex: "8B5CF6").opacity(0.35), radius: 12, x: 0, y: 6)
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }

            Text("설정")
                .font(.title2.weight(.bold))

            Text("API 키를 등록하면 더 많은 작품을 검색할 수 있어요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - API Keys

    private var apiKeysSection: some View {
        VStack(spacing: 16) {
            sectionTitle("API 키 설정", icon: "key.fill", color: Color(hex: "8B5CF6"))

            // TMDB
            apiKeyCard(
                title: "TMDB API Key",
                subtitle: "영화, 드라마 검색에 사용됩니다",
                icon: "movieclapper.fill",
                iconColor: Color(hex: "3B82F6"),
                key: $tmdbAPIKey,
                showKey: $showTMDBKey,
                linkTitle: "TMDB API Key 발급받기 →",
                linkURL: "https://www.themoviedb.org/settings/api"
            )

            // Kakao
            apiKeyCard(
                title: "Kakao API Key",
                subtitle: "소설 검색에 사용됩니다 (Kakao 책 검색 API)",
                icon: "character.book.closed.fill",
                iconColor: Color(hex: "F59E0B"),
                key: $kakaoAPIKey,
                showKey: $showKakaoKey,
                linkTitle: "Kakao Developers에서 발급받기 →",
                linkURL: "https://developers.kakao.com/"
            )

            // Free API notice
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "10B981"))
                Text("애니 검색(Jikan API)은 API 키 없이도 무료로 사용할 수 있어요")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
            .padding(14)
            .background(Color(hex: "10B981").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(hex: "10B981").opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }

    private func apiKeyCard(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        key: Binding<String>,
        showKey: Binding<Bool>,
        linkTitle: String,
        linkURL: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    withAnimation { showKey.wrappedValue.toggle() }
                } label: {
                    Image(systemName: showKey.wrappedValue ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 15))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }

            if showKey.wrappedValue {
                TextField(title + " 입력", text: key)
                    .font(.system(size: 13, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            } else {
                SecureField(title + " 입력", text: key)
                    .font(.system(size: 13))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }

            if let url = URL(string: linkURL) {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.circle")
                            .font(.system(size: 11))
                        Text(linkTitle)
                            .font(.caption.weight(.medium))
                    }
                    .foregroundColor(Color(hex: "8B5CF6"))
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: colorScheme == .dark ? .black.opacity(0.25) : .black.opacity(0.06), radius: 10, x: 0, y: 3)
        .padding(.horizontal, 20)
    }

    // MARK: - App Info

    private var appInfoSection: some View {
        VStack(spacing: 16) {
            sectionTitle("앱 정보", icon: "info.circle.fill", color: Color(.systemGray))

            VStack(spacing: 0) {
                infoRow(label: "버전", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0", icon: "tag.circle.fill", color: Color(hex: "6366F1"))

                Divider().padding(.leading, 56)

                infoRow(label: "앱 이름", value: "MediaDiary", icon: "books.vertical.fill", color: Color(hex: "8B5CF6"))

                Divider().padding(.leading, 56)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "F59E0B").opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "F59E0B"))
                        }
                        Text("지원하는 API")
                            .font(.subheadline.weight(.semibold))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        apiInfoRow("TMDB", detail: "영화/드라마 검색", icon: "movieclapper.fill", color: Color(hex: "3B82F6"))
                        apiInfoRow("Jikan", detail: "애니 검색 (무료)", icon: "sparkles.tv.fill", color: Color(hex: "EC4899"))
                        apiInfoRow("Kakao Books", detail: "소설 검색", icon: "character.book.closed.fill", color: Color(hex: "F59E0B"))
                        apiInfoRow("직접 입력", detail: "웹툰 등", icon: "rectangle.stack.fill", color: Color(hex: "10B981"))
                    }
                    .padding(.leading, 50)
                }
                .padding(14)
            }
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: colorScheme == .dark ? .black.opacity(0.25) : .black.opacity(0.06), radius: 10, x: 0, y: 3)
            .padding(.horizontal, 20)
        }
    }

    private func infoRow(label: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .padding(14)
    }

    private func apiInfoRow(_ name: String, detail: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 18)
            Text(name)
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary)
            Text("·")
                .foregroundColor(.secondary)
            Text(detail)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func sectionTitle(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 26, height: 26)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
            }
            Text(title)
                .font(.headline.weight(.bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }

    private func saveKeys() {
        UserDefaults.standard.set(tmdbAPIKey.trimmingCharacters(in: .whitespaces), forKey: "tmdb_api_key")
        UserDefaults.standard.set(kakaoAPIKey.trimmingCharacters(in: .whitespaces), forKey: "kakao_api_key")
        showSavedAlert = true
    }
}

#Preview {
    SettingsView()
}
