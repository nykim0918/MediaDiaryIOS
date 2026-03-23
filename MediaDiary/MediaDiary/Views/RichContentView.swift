//
//  RichContentView.swift
//  MediaDiary
//

import SwiftUI

// MARK: - Rich Content Display (Read-Only)

struct RichContentView: View {
    let blocks: [ReviewBlock]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(blocks) { block in
                blockView(for: block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func blockView(for block: ReviewBlock) -> some View {
        switch block.type {
        case .paragraph:
            if !block.text.isEmpty {
                Text(block.text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .heading:
            if !block.text.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    Text(block.text)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.primary)
                    LinearGradient(
                        colors: [Color(hex: "8B5CF6"), Color(hex: "6366F1")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 2.5)
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .quote:
            if !block.text.isEmpty {
                HStack(alignment: .top, spacing: 14) {
                    // Accent bar
                    LinearGradient(
                        colors: [Color(hex: "8B5CF6"), Color(hex: "6366F1")],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(width: 3.5)
                    .clipShape(Capsule())

                    Text(block.text)
                        .font(.body.italic())
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(14)
                .background(Color(hex: "8B5CF6").opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(hex: "8B5CF6").opacity(0.15), lineWidth: 1)
                )
            }

        case .image:
            if let filename = block.imageFilename,
               let uiImage = ImageStorageService.shared.load(filename: filename) {
                VStack(alignment: .center, spacing: 10) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                    if !block.caption.isEmpty {
                        Text(block.caption)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
            } else if block.imageFilename != nil {
                // Image file missing (e.g. after reinstall) — show placeholder
                HStack(spacing: 10) {
                    Image(systemName: "photo.slash")
                        .font(.system(size: 16))
                        .foregroundColor(Color(.tertiaryLabel))
                    Text("이미지를 불러올 수 없습니다")
                        .font(.caption)
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

        case .divider:
            HStack(spacing: 12) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.clear, Color(.systemGray4)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(height: 1)
                Image(systemName: "diamond.fill")
                    .font(.system(size: 5))
                    .foregroundColor(Color(.systemGray4))
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color(.systemGray4), .clear],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(height: 1)
            }
            .padding(.vertical, 4)
        }
    }
}
