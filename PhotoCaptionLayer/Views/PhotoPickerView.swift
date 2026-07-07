//
//  PhotoPickerView.swift
//  PhotoCaptionLayer
//
//  Screen 1 — Photo Picker.
//  A grid of recent library photos with photo-group selection and a Next button.
//

import SwiftUI
import Photos
import UIKit

struct PhotoPickerView: View {
    @EnvironmentObject private var viewModel: EditorViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 110), spacing: 3)
    ]

    var body: some View {
        content
            .navigationTitle("Select Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.enterEditor() }
                    } label: {
                        Label("Next", systemImage: "arrow.forward")
                            .labelStyle(.titleAndIcon)
                    }
                    .disabled(!viewModel.hasSelection)
                }
            }
            .overlay {
                if let status = permissionGate(for: viewModel.authorizationStatus) {
                    PermissionGate(message: status) {
                        Task { await viewModel.bootstrap() }
                    }
                }
            }
            .alert("Notice", isPresented: errorBinding, actions: {
                Button("OK", role: .cancel) { viewModel.dismissError() }
            }, message: {
                Text(viewModel.errorMessage ?? "")
            })
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { presented in
                if !presented { viewModel.dismissError() }
            }
        )
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.assets.isEmpty && viewModel.authorizationStatus == .authorized {
            emptyState
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    instructionCard
                    LazyVGrid(columns: columns, spacing: 3) {
                        ForEach(viewModel.assets, id: \.localIdentifier) { asset in
                            PhotoThumbnailView(asset: asset)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, viewModel.hasSelection ? 94 : 12)
            }
            .safeAreaInset(edge: .bottom) {
                if viewModel.hasSelection {
                    selectionBar
                }
            }
        }
    }

    private var instructionCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Choose up to \(viewModel.maxSelectionCount) photos")
                .font(.headline)
            Text("First selected photo is the main image. Other selected photos are used as OCR context, such as museum labels or detail shots.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Photos", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text("Your Photos library appears to be empty.")
        }
    }

    private var selectionBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.selectionStatusText)
                    .font(.subheadline.weight(.medium))
                Text("Caption will be saved to photo 1.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task { await viewModel.enterEditor() }
            } label: {
                Label("Next", systemImage: "arrow.forward")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: 160)
        }
        .padding()
        .background(.bar)
    }

    /// Returns a human-readable permission message when access is not granted.
    private func permissionGate(for status: PHAuthorizationStatus) -> String? {
        switch status {
        case .notDetermined:
            return nil
        case .denied, .restricted:
            return "Photo access is required. Enable it in Settings to select photos."
        case .authorized, .limited:
            return nil
        @unknown default:
            return nil
        }
    }
}

/// Shown when the user has denied photo access, with a deep link to Settings.
private struct PermissionGate: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Access Needed", systemImage: "lock.shield")
        } description: {
            Text(message)
        } actions: {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
