//
//  EditorViewModel.swift
//  PhotoCaptionLayer
//
//  Owns the enhancement pipeline state:
//      selected photo group → OCR context → caption → edit → write back to Photos
//
//  All `@Published` mutations happen on the main actor. Long-running work is
//  dispatched to the service layer (which itself moves to background queues).
//

import SwiftUI
import Photos
import UIKit
import Combine

@MainActor
final class EditorViewModel: ObservableObject {
    // MARK: - Services
    let photoLibrary = PhotoLibraryService.shared
    let ocr = OCRService.shared
    let captionService = CaptionService.shared
    let writer = PhotoWriterService.shared

    // MARK: - Authorization & library state
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published private(set) var assets: [PHAsset] = []
    /// `localIdentifier` -> thumbnail image.
    @Published private(set) var thumbnails: [String: UIImage] = [:]
    @Published var selectedAssetIDs: Set<String> = []
    @Published private(set) var selectedAssetOrder: [String] = []

    let maxSelectionCount = 6

    // MARK: - Editor state
    @Published var detailImage: UIImage?
    @Published var ocrResults: [OCRResult] = []
    @Published var ocrText: String = ""
    /// Pure OCR text used to build captions. Unlike `ocrText`, this excludes
    /// display-only labels such as "Photo 1:" and section dividers.
    private var captionSourceOCRText: String = ""
    @Published var caption = Caption(object: "", context: "", explanation: "")
    @Published var phase: ProcessingPhase = .idle
    @Published var isWriting = false
    @Published var errorMessage: String?
    @Published var route: AppRoute?

    /// The first selected asset. Caption writeback targets this photo only.
    private(set) var editingAsset: PHAsset?

    /// All selected assets for the current edit session. The first asset is the
    /// writeback target; all selected assets are used as OCR context.
    private(set) var editingAssets: [PHAsset] = []

    // MARK: - Lifecycle

    func bootstrap() async {
        let status = await photoLibrary.requestAuthorization()
        authorizationStatus = status
        if photoLibrary.isAuthorized {
            await reloadAssets()
        }
    }

    func reloadAssets() async {
        assets = photoLibrary.fetchImageAssets()
    }

    // MARK: - Selection

    var hasSelection: Bool { !selectedAssetIDs.isEmpty }

    var selectionStatusText: String {
        "\(selectedAssetIDs.count) / \(maxSelectionCount) selected"
    }

    var hasRecognizedText: Bool {
        !captionSourceOCRText.isEmpty
    }

    func toggleSelection(_ asset: PHAsset) {
        let id = asset.localIdentifier
        if selectedAssetIDs.contains(id) {
            selectedAssetIDs.remove(id)
            selectedAssetOrder.removeAll { $0 == id }
        } else {
            guard selectedAssetIDs.count < maxSelectionCount else {
                errorMessage = "You can select up to \(maxSelectionCount) photos. Use the first photo as the main image and the rest as OCR context."
                return
            }
            selectedAssetIDs.insert(id)
            selectedAssetOrder.append(id)
        }
    }

    var selectedAssets: [PHAsset] {
        let byID = Dictionary(uniqueKeysWithValues: assets.map { ($0.localIdentifier, $0) })
        return selectedAssetOrder.compactMap { byID[$0] }
    }

    // MARK: - Navigation: Picker -> Editor

    /// Loads the first selected asset as the main image and enters the editor.
    /// Additional selected assets are kept as OCR context sources.
    func enterEditor() async {
        let selected = selectedAssets
        guard let asset = selected.first else {
            errorMessage = "No photo selected."
            return
        }

        editingAsset = asset
        editingAssets = selected
        phase = .loadingImage
        route = .editor

        let image = await photoLibrary.loadDetailImage(
            for: asset,
            maxDimension: AppConstants.detailImageMaxDimension
        )
        detailImage = image

        // Prefill any previously written caption for the main asset.
        if let existing = await writer.readCaption(for: asset) {
            caption = existing
            phase = .captionReady
            AppLog.lifecycle.info("Loaded existing caption for main asset.")
        } else {
            phase = .idle
        }

        if image == nil {
            errorMessage = "Could not load the main photo. If it is in iCloud, wait for it to download and try again."
        }
    }

    // MARK: - OCR

    /// Runs Vision OCR on every selected asset and generates one grounded
    /// caption. The caption is written only to the first selected photo.
    func runOCR() async {
        guard !editingAssets.isEmpty else {
            errorMessage = "No photos loaded for OCR."
            return
        }
        phase = .ocrRunning
        ocrResults = []
        ocrText = ""
        captionSourceOCRText = ""

        var displayGroups: [String] = []
        var captionTextGroups: [String] = []
        var allResults: [OCRResult] = []

        for (index, asset) in editingAssets.enumerated() {
            let image: UIImage?
            if index == 0, let loadedMainImage = detailImage {
                image = loadedMainImage
            } else {
                image = await photoLibrary.loadDetailImage(
                    for: asset,
                    maxDimension: AppConstants.detailImageMaxDimension
                )
                if index == 0 {
                    detailImage = image
                }
            }

            guard let image else {
                displayGroups.append("Photo \(index + 1): Could not load image.")
                continue
            }

            let results = await ocr.recognizeText(in: image)
            allResults.append(contentsOf: results)

            let text = results.map(\.text).joined(separator: "\n")
            if text.isEmpty {
                displayGroups.append("Photo \(index + 1): No text recognised.")
            } else {
                displayGroups.append("Photo \(index + 1):\n\(text)")
                captionTextGroups.append(text)
            }
        }

        ocrResults = allResults
        ocrText = displayGroups.joined(separator: "\n\n---\n\n")
        captionSourceOCRText = captionTextGroups.joined(separator: "\n")

        // Generate a grounded caption from pure OCR text only. UI labels such as
        // "Photo 1:" must not leak into the Object/Context fields.
        caption = captionService.buildCaption(from: captionSourceOCRText)
        phase = .captionReady
    }

    // MARK: - Caption editing

    /// Rebuilds the caption from current OCR text, discarding manual edits.
    func applyOCRCaption() {
        caption = captionService.buildCaption(from: captionSourceOCRText)
    }

    // MARK: - Write back

    /// Writes the current caption into the first selected asset's adjustment data.
    func writeCaption() async {
        guard let asset = editingAsset else {
            errorMessage = "No main photo to write to."
            return
        }
        guard !caption.isEmpty else {
            errorMessage = "Caption is empty. Add some text or run OCR first."
            return
        }

        isWriting = true
        phase = .writing
        defer { isWriting = false }

        do {
            try await writer.writeCaption(caption, to: asset)
            route = .success
        } catch {
            errorMessage = error.localizedDescription
            phase = .captionReady
        }
    }

    // MARK: - Reset

    /// Clears editor state to return to the picker for another photo group.
    func resetToPicker() {
        detailImage = nil
        ocrResults = []
        ocrText = ""
        captionSourceOCRText = ""
        caption = Caption()
        editingAsset = nil
        editingAssets = []
        phase = .idle
        errorMessage = nil
        route = nil
        selectedAssetIDs.removeAll()
        selectedAssetOrder.removeAll()
    }

    func dismissError() {
        errorMessage = nil
    }

    // MARK: - Thumbnail loading

    func loadThumbnailIfNeeded(for asset: PHAsset) async {
        guard thumbnails[asset.localIdentifier] == nil else { return }
        let image = await photoLibrary.loadThumbnail(
            for: asset,
            targetSize: AppConstants.thumbnailSize
        )
        if let image {
            thumbnails[asset.localIdentifier] = image
        }
    }

}
