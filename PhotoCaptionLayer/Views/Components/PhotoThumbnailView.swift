//
//  PhotoThumbnailView.swift
//  PhotoCaptionLayer
//
//  A single selectable thumbnail cell in the picker grid. Reflects the
//  selection state and order within the current photo group.
//

import SwiftUI
import Photos

struct PhotoThumbnailView: View {
    @EnvironmentObject private var viewModel: EditorViewModel
    let asset: PHAsset

    private var thumbnail: UIImage? {
        viewModel.thumbnails[asset.localIdentifier]
    }

    private var isSelected: Bool {
        viewModel.selectedAssetIDs.contains(asset.localIdentifier)
    }

    private var selectionOrder: Int? {
        viewModel.selectedAssetOrder.firstIndex(of: asset.localIdentifier)
    }

    var body: some View {
        Button {
            viewModel.toggleSelection(asset)
        } label: {
            ZStack(alignment: .bottomTrailing) {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0)
                        .clipped()
                        .aspectRatio(1, contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color(.secondarySystemBackground))
                        .overlay(ProgressView())
                        .aspectRatio(1, contentMode: .fill)
                }

                if let order = selectionOrder {
                    Text("\(order + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(Color.accentColor, in: Circle())
                        .padding(8)
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: 2)
                                .padding(5)
                        )
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 3)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .task {
            await viewModel.loadThumbnailIfNeeded(for: asset)
        }
    }
}
