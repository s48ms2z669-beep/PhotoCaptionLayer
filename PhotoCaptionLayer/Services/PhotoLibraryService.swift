//
//  PhotoLibraryService.swift
//  PhotoCaptionLayer
//
//  Reads PHAssets from the iOS Photos library, manages authorization, and
//  loads thumbnail / detail images via PHImageManager. This is the ONLY
//  component that talks to PHPhotoLibrary for reads.
//

import Photos
import UIKit

final class PhotoLibraryService {
    static let shared = PhotoLibraryService()
    private init() {}

    // MARK: - Authorization

    /// Current read/write authorization status.
    var currentAuthorization: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    /// Requests read/write access. Returns the resulting status.
    @discardableResult
    func requestAuthorization() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        AppLog.photoLibrary.info("Authorization status: \(status.rawValue)")
        return status
    }

    var isAuthorized: Bool {
        let status = currentAuthorization
        return status == .authorized || status == .limited
    }

    // MARK: - Fetching assets

    /// Returns recent image assets, newest first.
    func fetchImageAssets() -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        options.fetchLimit = AppConstants.pickerFetchLimit
        options.predicate = NSPredicate(format: "(mediaType == %d)", PHAssetMediaType.image.rawValue)

        let result = PHAsset.fetchAssets(with: options)
        var assets: [PHAsset] = []
        assets.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }

    // MARK: - Image loading

    /// Loads a square-ish thumbnail suitable for the picker grid.
    func loadThumbnail(for asset: PHAsset, targetSize: CGFloat) async -> UIImage? {
        let size = CGSize(width: targetSize, height: targetSize)
        return await requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            deliveryMode: .opportunistic,
            resizeMode: .fast
        )
    }

    /// Loads a detail image (bounded by the longest side) used for both the
    /// editor preview and OCR. A bounded size keeps Vision fast on huge photos.
    func loadDetailImage(for asset: PHAsset, maxDimension: CGFloat) async -> UIImage? {
        let aspect = asset.aspectRatio
        let targetSize: CGSize
        if aspect >= 1 {
            targetSize = CGSize(width: maxDimension, height: maxDimension / aspect)
        } else {
            targetSize = CGSize(width: maxDimension * aspect, height: maxDimension)
        }
        return await requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            deliveryMode: .highQualityFormat,
            resizeMode: .fast
        )
    }

    // MARK: - Private

    private func requestImage(
        for asset: PHAsset,
        targetSize: CGSize,
        contentMode: PHImageContentMode,
        deliveryMode: PHImageRequestOptionsDeliveryMode,
        resizeMode: PHImageRequestOptionsResizeMode
    ) async -> UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = deliveryMode
        options.resizeMode = resizeMode
        options.isNetworkAccessAllowed = true
        options.version = .current

        let timeoutNanoseconds: UInt64
        if deliveryMode == .highQualityFormat {
            timeoutNanoseconds = 15_000_000_000
        } else {
            timeoutNanoseconds = 6_000_000_000
        }

        return await withCheckedContinuation { continuation in
            // Guard against any double-delivery so the continuation resumes once.
            let resumeGate = ResumeGate()
            let requestState = ImageRequestState()

            let requestID = PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: contentMode,
                options: options
            ) { image, info in
                let cancelled = (info?[PHImageCancelledKey] as? NSNumber)?.boolValue ?? false
                if cancelled {
                    resumeGate.resumeOnce(continuation, with: nil)
                    return
                }

                if let error = info?[PHImageErrorKey] as? Error {
                    AppLog.photoLibrary.error("Image request failed: \(error.localizedDescription)")
                    resumeGate.resumeOnce(continuation, with: nil)
                    return
                }

                let degraded = (info?[PHImageResultIsDegradedKey] as? NSNumber)?.boolValue ?? false

                // Thumbnails can safely use a degraded image as a fast fallback.
                // Detail images wait for the final high-quality delivery or timeout.
                if deliveryMode == .opportunistic, let image {
                    resumeGate.resumeOnce(continuation, with: image)
                    return
                }

                guard !degraded else { return }
                resumeGate.resumeOnce(continuation, with: image)
            }
            requestState.set(requestID)

            Task.detached {
                try? await Task.sleep(nanoseconds: timeoutNanoseconds)
                if resumeGate.resumeOnce(continuation, with: nil) {
                    PHImageManager.default().cancelImageRequest(requestState.get())
                    AppLog.photoLibrary.warning("Image request timed out and was cancelled.")
                }
            }
        }
    }
}

private extension PHAsset {
    var aspectRatio: CGFloat {
        guard pixelHeight > 0 else { return 1 }
        return CGFloat(pixelWidth) / CGFloat(pixelHeight)
    }
}

/// Ensures a `CheckedContinuation` is only resumed a single time, even if the
/// image manager delivers multiple callbacks.
private final class ResumeGate: @unchecked Sendable {
    private var resumed = false
    private let lock = NSLock()

    @discardableResult
    func resumeOnce(_ continuation: CheckedContinuation<UIImage?, Never>, with image: UIImage?) -> Bool {
        lock.lock()
        let shouldResume = !resumed
        if shouldResume {
            resumed = true
        }
        lock.unlock()
        if shouldResume {
            continuation.resume(returning: image)
        }
        return shouldResume
    }
}

private final class ImageRequestState: @unchecked Sendable {
    private var requestID = PHInvalidImageRequestID
    private let lock = NSLock()

    func set(_ id: PHImageRequestID) {
        lock.lock()
        requestID = id
        lock.unlock()
    }

    func get() -> PHImageRequestID {
        lock.lock()
        let id = requestID
        lock.unlock()
        return id
    }
}
