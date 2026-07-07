//
//  PhotoWriterService.swift
//  PhotoCaptionLayer
//
//  Writes the caption back into the iOS Photos metadata layer using
//  `PHContentEditingOutput` + `PHAdjustmentData`.
//
//  PHOTOS WRITEBACK RULES
//  ----------------------
//  • Use PHPhotoLibrary.shared().performChanges.
//  • Use PHAssetChangeRequest + PHContentEditingOutput + PHAdjustmentData.
//  • Do NOT modify the original image pixels: the rendered content written to
//    `renderedContentURL` is a byte-for-byte copy of the original full-size
//    image, so the visible photo is unchanged.
//  • The caption lives entirely inside `adjustmentData.data` as JSON and is
//    retrievable later (see `readCaption(for:)`).
//  • Because the edit is non-destructive, the user can revert it from the system
//    Photos app, which honours our formatIdentifier/formatVersion.
//

import Photos
import UIKit
import Foundation

enum PhotoWriterError: LocalizedError {
    case missingEditingInput
    case missingFullSizeImage
    case copyFailed(String)
    case performChangesFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingEditingInput:
            return "Could not open the photo for editing. If it is stored in iCloud, make sure it has finished downloading."
        case .missingFullSizeImage:
            return "The original full-size image could not be loaded for writeback."
        case .copyFailed(let detail):
            return "Failed to prepare the edited photo: \(detail)"
        case .performChangesFailed(let detail):
            return "Photos rejected the write: \(detail)"
        }
    }
}

/// Codable payload stored inside `PHAdjustmentData.data`.
struct CaptionAdjustmentPayload: Codable, Equatable {
    let caption: Caption
    let createdAt: Date
    let appVersion: String
}

final class PhotoWriterService {
    static let shared = PhotoWriterService()
    private init() {}

    private let formatIdentifier = AppConstants.adjustmentFormatIdentifier
    private let formatVersion = AppConstants.adjustmentFormatVersion

    // MARK: - Write

    /// Attaches `caption` to `asset` as non-destructive adjustment data.
    ///
    /// The visible image is left unchanged: the original full-size image is
    /// copied verbatim to `renderedContentURL`, and the caption is encoded as
    /// JSON inside `adjustmentData`.
    func writeCaption(_ caption: Caption, to asset: PHAsset) async throws {
        AppLog.writer.info("Preparing non-destructive write for asset \(asset.localIdentifier)")

        // 1. Obtain a content editing input (also triggers iCloud download).
        guard let input = try await requestEditingInput(for: asset) else {
            throw PhotoWriterError.missingEditingInput
        }

        // 2. Create the editing output bound to that input.
        let output = PHContentEditingOutput(contentEditingInput: input)

        // 3. Copy the ORIGINAL full-size image to the rendered content URL so
        //    the visible photo is byte-for-byte identical to the source.
        let sourceURL = input.fullSizeImageURL
        guard let sourceURL else {
            throw PhotoWriterError.missingFullSizeImage
        }
        try copyOriginalImage(from: sourceURL, to: output.renderedContentURL)

        // 4. Encode the caption into adjustmentData. This is the metadata layer.
        let payload = CaptionAdjustmentPayload(
            caption: caption,
            createdAt: Date(),
            appVersion: formatVersion
        )
        let payloadData = try JSONEncoder().encode(payload)

        output.adjustmentData = PHAdjustmentData(
            formatIdentifier: formatIdentifier,
            formatVersion: formatVersion,
            data: payloadData
        )

        // 5. Commit the change inside PhotosKit's performChanges block.
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest(for: asset)
                request.contentEditingOutput = output
            }
            AppLog.writer.info("Caption written successfully.")
        } catch {
            AppLog.writer.error("performChanges failed: \(error.localizedDescription)")
            throw PhotoWriterError.performChangesFailed(error.localizedDescription)
        }
    }

    // MARK: - Read

    /// Reads back a previously written caption for the asset, if any.
    func readCaption(for asset: PHAsset) async -> Caption? {
        guard let input = try? await requestEditingInput(for: asset),
              let adjustment = input.adjustmentData,
              adjustment.formatIdentifier == formatIdentifier,
              adjustment.formatVersion == formatVersion else {
            return nil
        }

        let payload = try? JSONDecoder().decode(
            CaptionAdjustmentPayload.self,
            from: adjustment.data
        )
        return payload?.caption
    }

    // MARK: - Private

    private func requestEditingInput(for asset: PHAsset) async throws -> PHContentEditingInput? {
        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = true
        options.canHandleAdjustmentData = { _ in true }

        return try await withCheckedThrowingContinuation { continuation in
            let gate = ContinuationGate<PHContentEditingInput?>()

            asset.requestContentEditingInput(with: options) { input, info in
                let error = info?[PHContentEditingInputErrorKey] as? Error
                let isDegraded = (info?[PHContentEditingInputResultIsDegradedKey] as? NSNumber)?.boolValue ?? false

                // Only resolve on the final (non-degraded) delivery or on error.
                if isDegraded { return }

                if let error {
                    gate.resumeOnceThrowing(continuation, with: .failure(error))
                } else {
                    gate.resumeOnceThrowing(continuation, with: .success(input))
                }
            }
        }
    }

    /// Copies the source image file to the destination URL, replacing any
    /// existing file. We deliberately copy (not transcode) to preserve the
    /// original pixels — this is the crux of the "do not modify the image" rule.
    private func copyOriginalImage(from source: URL, to destination: URL) throws {
        let manager = FileManager.default
        if manager.fileExists(atPath: destination.path) {
            try manager.removeItem(at: destination)
        }
        do {
            try manager.copyItem(at: source, to: destination)
        } catch {
            throw PhotoWriterError.copyFailed(error.localizedDescription)
        }
    }
}

/// Ensures a throwing continuation resumes exactly once, guarding against
/// PhotosKit delivering multiple callbacks for a single request.
private final class ContinuationGate<T>: @unchecked Sendable {
    private var resumed = false
    private let lock = NSLock()

    func resumeOnceThrowing(
        _ continuation: CheckedThrowingContinuation<T, Error>,
        with result: Result<T, Error>
    ) {
        lock.lock()
        let shouldResume = !resumed
        resumed = true
        lock.unlock()
        if shouldResume {
            switch result {
            case .success(let value):
                continuation.resume(returning: value)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
}
