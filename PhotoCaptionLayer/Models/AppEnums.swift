//
//  AppEnums.swift
//  PhotoCaptionLayer
//
//  Lightweight domain types shared across views and the view model.
//

import Foundation

/// Navigation destinations for the main flow.
enum AppRoute: Hashable {
    case editor
    case success
}

/// Progress of the enhancement pipeline.
/// Drives UI affordances (spinners, disabled buttons, status text).
enum ProcessingPhase: Equatable {
    case idle
    case loadingImage
    case ocrRunning
    case captionReady
    case writing
}
