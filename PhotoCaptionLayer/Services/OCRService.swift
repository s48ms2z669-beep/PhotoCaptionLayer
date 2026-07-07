//
//  OCRService.swift
//  PhotoCaptionLayer
//
//  Extracts text from a UIImage using the Vision framework
//  (`VNRecognizeTextRequest`). Tuned for signage / museum information boards:
//  accurate recognition, language correction, multi-language support.
//
//  Output is clean text only — no bounding boxes leaked to the caption.
//

import Vision
import UIKit
import Foundation

/// A single recognised text line with confidence and normalised bounding box.
struct OCRResult: Identifiable, Equatable, Hashable {
    let id = UUID()
    let text: String
    let confidence: Float
    /// Normalised to the image coordinate space (origin bottom-left).
    let boundingBox: CGRect
}

final class OCRService {
    static let shared = OCRService()
    private init() {}

    /// Runs text recognition on the supplied image and returns recognised lines.
    func recognizeText(in image: UIImage) async -> [OCRResult] {
        guard let cgImage = image.cgImage else {
            AppLog.ocr.error("Image had no backing CGImage; OCR aborted.")
            return []
        }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let results = observations.compactMap { observation -> OCRResult? in
                    guard let top = observation.topCandidates(1).first else { return nil }
                    let cleaned = top.string
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !cleaned.isEmpty else { return nil }
                    return OCRResult(
                        text: cleaned,
                        confidence: top.confidence,
                        boundingBox: observation.boundingBox
                    )
                }
                AppLog.ocr.info("Recognised \(results.count) text blocks.")
                continuation.resume(returning: results)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = Self.preferredLanguages

            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    AppLog.ocr.error("Vision request failed: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                }
            }
        }
    }

    /// Languages tried in priority order. Chinese variants first to suit the
    /// museum/signage use case, then English and Japanese for travel photos.
    private static let preferredLanguages = [
        "zh-Hans",
        "zh-Hant",
        "en-US",
        "ja-JP"
    ]
}
