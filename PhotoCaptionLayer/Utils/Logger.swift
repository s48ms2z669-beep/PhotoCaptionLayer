//
//  Logger.swift
//  PhotoCaptionLayer
//
//  A tiny os_log wrapper so service code can emit structured logs without
//  pulling in third-party dependencies.
//

import Foundation
import os

enum AppLog {
    private static let subsystem = "com.photocaptionlayer"

    static let photoLibrary = Logger(subsystem: subsystem, category: "PhotoLibrary")
    static let ocr = Logger(subsystem: subsystem, category: "OCR")
    static let caption = Logger(subsystem: subsystem, category: "Caption")
    static let writer = Logger(subsystem: subsystem, category: "Writer")
    static let lifecycle = Logger(subsystem: subsystem, category: "Lifecycle")
}
