//
//  RichReviewEditor.swift
//  MediaDiary
//

import SwiftUI
import PhotosUI

// MARK: - Rich Review Editor (Edit Mode)

struct RichReviewEditor: View {
    @Binding var blocks: [ReviewBlock]
    @Environment(\.colorScheme) private var colorScheme

    // Photo picker — use a SEPARATE bool for presentation so the dismiss
    // handler doesn't clear imagePickerTargetID before onChange fires.
    @State private var showImagePicker = false
    @State private var imagePickerTargetID: UUID? = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    @State private var focusedBlockID: UUID? = nil

    var body: some View {
        VStack(spacing: 0) {
            blockList
            addToolbar
        }
        // Place photosPicker at root so it isn't inside a ForEach
        .photosPicker(isPresented: $showImagePicker,
                      selection: $selectedPhotoItem,
                      matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            // Capture targetID synchronously before any async work
            let targetID = imagePickerTargetID
            guard let targetID else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data),
                   let filename = ImageStorageService.shared.save(uiImage) {
                    await MainActor.run {
                        if let idx = blocks.firstIndex(where: { $0.id == targetID }) {
                            blocks[idx].imageFilename = filename
                        }
                    }
                }
                await MainActor.run {
                    imagePickerTargetID = nil
                    selectedPhotoItem = nil
                }
            }
        }
    }

    // MARK: - Block List

    private var blockList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach($blocks) { $block in
                    BlockEditorRow(
                        block: $block,
                        isFocused: focusedBlockID == block.id,
                        onFocus: { focusedBlockID = block.id },
                        onDelete: { deleteBlock(block) },
                        onPickImage: {
                            imagePickerTargetID = block.id
                            showImagePicker = true
                        },
                        onMoveUp: { moveBlock(block, direction: -1) },
                        onMoveDown: { moveBlock(block, direction: 1) }
                    )
                    .padding(.horizontal, 16)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
                }

                if blocks.isEmpty {
                    emptyEditorPlaceholder
                }

                Color.clear.frame(height: 100)
            }
            .padding(.top, 12)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Add Toolbar

    private var addToolbar: some View {
        VStack(spacing: 0) {
            // Thin separator
            Rectangle()
                .fill(Color(.separator).opacity(0.5))
                .frame(height: 0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ReviewBlockType.allCases, id: \.self) { blockType in
                        Button {
                            addBlock(of: blockType)
                        } label: {
                            VStack(spacing: 5) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color(hex: "8B5CF6").opacity(0.1))
                                        .frame(width: 38, height: 38)
                                    Image(systemName: blockType.icon)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color(hex: "8B5CF6"))
                                }
                                Text(blockType.displayName)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color(hex: "8B5CF6"))
                            }
                            .frame(width: 52)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Empty Placeholder

    private var emptyEditorPlaceholder: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "8B5CF6").opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "text.badge.plus")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(Color(hex: "8B5CF6").opacity(0.5))
            }
            VStack(spacing: 6) {
                Text("아직 작성된 블록이 없어요")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
                Text("아래 버튼으로 본문, 제목, 사진 등\n다양한 블록을 추가해보세요")
                    .font(.caption)
                    .foregroundColor(Color(.tertiaryLabel))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Actions

    private func addBlock(of type: ReviewBlockType) {
        let newBlock = ReviewBlock(type: type)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            blocks.append(newBlock)
            focusedBlockID = newBlock.id
        }
    }

    private func deleteBlock(_ block: ReviewBlock) {
        if let filename = block.imageFilename {
            ImageStorageService.shared.delete(filename: filename)
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            blocks.removeAll { $0.id == block.id }
        }
    }

    private func moveBlock(_ block: ReviewBlock, direction: Int) {
        guard let idx = blocks.firstIndex(where: { $0.id == block.id }) else { return }
        let newIdx = idx + direction
        guard newIdx >= 0, newIdx < blocks.count else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            blocks.move(fromOffsets: IndexSet(integer: idx), toOffset: direction > 0 ? newIdx + 1 : newIdx)
        }
    }
}

// MARK: - Block Editor Row

struct BlockEditorRow: View {
    @Binding var block: ReviewBlock
    let isFocused: Bool
    let onFocus: () -> Void
    let onDelete: () -> Void
    let onPickImage: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var accentColor: Color { Color(hex: "8B5CF6") }

    var body: some View {
        VStack(spacing: 0) {
            // Block type header bar
            blockHeader

            // Block content
            blockContent
                .padding(block.type == .divider ? 0 : 14)
        }
        .background(blockBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    isFocused ? accentColor.opacity(0.4) : Color(.separator).opacity(0.5),
                    lineWidth: isFocused ? 1.5 : 0.5
                )
        )
        .shadow(
            color: isFocused ? accentColor.opacity(0.08) : .black.opacity(colorScheme == .dark ? 0.2 : 0.04),
            radius: isFocused ? 8 : 4, x: 0, y: 2
        )
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .contentShape(Rectangle())
        .onTapGesture { onFocus() }
    }

    // MARK: Block Header

    private var blockHeader: some View {
        HStack(spacing: 8) {
            // Type pill
            HStack(spacing: 5) {
                Image(systemName: block.type.icon)
                    .font(.system(size: 10, weight: .bold))
                Text(block.type.displayName)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(accentColor.opacity(0.1))
            .clipShape(Capsule())

            Spacer()

            // Move up/down
            HStack(spacing: 2) {
                Button(action: onMoveUp) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(.secondaryLabel))
                        .frame(width: 26, height: 26)
                        .background(Color(.quaternarySystemFill))
                        .clipShape(Circle())
                }
                Button(action: onMoveDown) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(.secondaryLabel))
                        .frame(width: 26, height: 26)
                        .background(Color(.quaternarySystemFill))
                        .clipShape(Circle())
                }
            }

            // Delete
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.red.opacity(0.7))
                    .frame(width: 26, height: 26)
                    .background(Color.red.opacity(0.08))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            colorScheme == .dark
                ? Color(.tertiarySystemBackground).opacity(0.8)
                : Color(.secondarySystemBackground).opacity(0.6)
        )
    }

    // MARK: Block Content

    @ViewBuilder
    private var blockContent: some View {
        switch block.type {
        case .paragraph:
            paragraphEditor
        case .heading:
            headingEditor
        case .quote:
            quoteEditor
        case .image:
            imageBlock
        case .divider:
            dividerBlock
        }
    }

    private var blockBackground: some ShapeStyle {
        colorScheme == .dark
            ? AnyShapeStyle(Color(.secondarySystemBackground))
            : AnyShapeStyle(Color.white)
    }

    // MARK: Paragraph

    private var paragraphEditor: some View {
        TextField("본문을 입력하세요...", text: $block.text, axis: .vertical)
            .font(.body)
            .lineLimit(1...30)
            .tint(accentColor)
            .onTapGesture { onFocus() }
    }

    // MARK: Heading

    private var headingEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("제목을 입력하세요", text: $block.text, axis: .vertical)
                .font(.title3.weight(.bold))
                .lineLimit(1...4)
                .tint(accentColor)
                .onTapGesture { onFocus() }
            // Gradient rule
            LinearGradient(
                colors: [Color(hex: "8B5CF6"), Color(hex: "6366F1")],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 2.5)
            .clipShape(Capsule())
        }
    }

    // MARK: Quote

    private var quoteEditor: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "8B5CF6"), Color(hex: "6366F1")],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 3)
                .padding(.vertical, 2)

            TextField("인용구를 입력하세요...", text: $block.text, axis: .vertical)
                .font(.body.italic())
                .foregroundColor(.secondary)
                .lineLimit(1...12)
                .tint(accentColor)
                .onTapGesture { onFocus() }
        }
    }

    // MARK: Image

    private var imageBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let filename = block.imageFilename,
               let uiImage = ImageStorageService.shared.load(filename: filename) {
                // Image loaded
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)

                    // Replace button
                    Button(action: onPickImage) {
                        HStack(spacing: 5) {
                            Image(systemName: "photo.badge.arrow.down.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text("교체")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial.opacity(0.92))
                        .background(Color.black.opacity(0.4))
                        .clipShape(Capsule())
                    }
                    .padding(10)
                }
            } else {
                // Picker placeholder
                Button(action: onPickImage) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.1))
                                .frame(width: 56, height: 56)
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(accentColor)
                        }
                        Text("사진 선택")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(accentColor)
                        Text("탭하여 갤러리에서 사진을 선택하세요")
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(accentColor.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(accentColor.opacity(0.25),
                                    style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                    )
                }
            }

            // Caption
            HStack(spacing: 6) {
                Image(systemName: "text.below.photo")
                    .font(.system(size: 11))
                    .foregroundColor(Color(.tertiaryLabel))
                TextField("사진 설명 추가 (선택사항)", text: $block.caption)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .tint(accentColor)
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: Divider

    private var dividerBlock: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.clear, Color(.systemGray4)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(height: 1)
                Image(systemName: "diamond.fill")
                    .font(.system(size: 6))
                    .foregroundColor(Color(.systemGray3))
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color(.systemGray4), .clear],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(height: 1)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
    }
}
