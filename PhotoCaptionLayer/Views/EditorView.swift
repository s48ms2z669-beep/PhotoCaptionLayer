//
//  EditorView.swift
//  PhotoCaptionLayer
//
//  Screen 2 — Editor.
//  Shows the main image preview, OCR text from the selected photo group, and
//  an editable structured caption with "Use OCR" and writeback actions.
//

import SwiftUI
import Photos

struct EditorView: View {
    @EnvironmentObject private var viewModel: EditorViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                groupNotice
                imagePreview
                ocrSection
                captionSection
                actionButtons
            }
            .padding()
        }
        .navigationTitle("Caption")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    viewModel.resetToPicker()
                }
            }
        }
        .alert("Something went wrong", isPresented: errorBinding, actions: {
            Button("OK", role: .cancel) { viewModel.dismissError() }
        }, message: {
            Text(viewModel.errorMessage ?? "")
        })
    }

    /// Proper two-way binding so the alert actually dismisses when the user
    /// taps OK (a `.constant` would leave it stuck open).
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { presented in
                if !presented { viewModel.dismissError() }
            }
        )
    }

    private var groupNotice: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Photo group", systemImage: "rectangle.stack")
                .font(.headline)
            Text(groupNoticeText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var groupNoticeText: String {
        if viewModel.editingAssets.count <= 1 {
            return "Photo 1 is the main image and writeback target. Add label or detail photos from the picker when more OCR context is needed."
        }
        return "Photo 1 is the main image and writeback target. Photos 2–\(viewModel.editingAssets.count) are used only as OCR context."
    }

    // MARK: - Image preview

    @ViewBuilder
    private var imagePreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    if let image = viewModel.detailImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else if viewModel.phase == .loadingImage {
                        ProgressView("Loading main photo…")
                    } else {
                        ContentUnavailableView("No image", systemImage: "photo")
                    }
                }
        }
    }

    // MARK: - OCR section

    private var ocrSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Recognised Text", systemImage: "text.viewfinder")
                    .font(.headline)
                Spacer()
                if viewModel.phase == .ocrRunning {
                    ProgressView()
                }
            }

            if viewModel.ocrText.isEmpty {
                Text("No text recognised yet. Run OCR to read signs, labels, or information boards from the selected photo group.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ScrollView {
                    Text(viewModel.ocrText)
                        .font(.callout.monospaced())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 200)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                Task { await viewModel.runOCR() }
            } label: {
                Label(viewModel.ocrText.isEmpty ? "Run OCR on Photo Group" : "Re-run OCR", systemImage: "text.magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(viewModel.editingAssets.isEmpty || viewModel.phase == .ocrRunning)
        }
    }

    // MARK: - Caption editor

    private var captionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Caption", systemImage: "text.badge.plus")
                    .font(.headline)
                Spacer()
                Button("Use OCR") {
                    viewModel.applyOCRCaption()
                }
                .font(.subheadline.weight(.semibold))
                .disabled(!viewModel.hasRecognizedText)
            }

            CaptionFieldView(caption: $viewModel.caption)

            if !viewModel.caption.isEmpty {
                PreviewCard(text: viewModel.caption.formatted)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.caption.formatted)
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Caption will be saved only to photo 1. Other selected photos are context sources and will not be modified.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button {
                Task { await viewModel.writeCaption() }
            } label: {
                Label(
                    viewModel.isWriting ? "Writing…" : "Write to Main Photo",
                    systemImage: viewModel.isWriting ? "arrow.triangle.2.circlepath" : "square.and.arrow.down"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isWriting || viewModel.caption.isEmpty || viewModel.phase == .ocrRunning)
        }
        .padding(.top, 4)
    }
}

/// A small card that previews exactly how the caption will read when written.
private struct PreviewCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Preview")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.accentColor.opacity(0.4), lineWidth: 1)
        )
    }
}
