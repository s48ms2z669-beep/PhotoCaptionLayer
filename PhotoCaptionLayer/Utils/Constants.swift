//
//  Constants.swift
//  PhotoCaptionLayer
//
//  Centralised configuration for the semantic enhancement layer.
//

import Foundation
import CoreGraphics

enum AppConstants {
    /// Bundle-style identifier used for our non-destructive adjustment data.
    /// PhotosKit uses this pair to attribute edits to this app and to allow
    /// reverting from the system Photos app.
    static let adjustmentFormatIdentifier = "com.photocaptionlayer.caption"
    static let adjustmentFormatVersion = "1.0"

    /// Thumbnail target size for the picker grid.
    static let thumbnailSize: CGFloat = 220

    /// Maximum dimension (longest side) of the detail image loaded for the
    /// editor preview and OCR. Keeping this bounded keeps Vision OCR fast on
    /// very large device photos without sacrificing recognisable signage text.
    static let detailImageMaxDimension: CGFloat = 2400

    /// How many recent assets to show in the picker grid.
    /// Thumbnails are loaded lazily as cells appear on screen.
    static let pickerFetchLimit = 500
}
