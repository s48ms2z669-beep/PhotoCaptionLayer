//
//  Caption.swift
//  PhotoCaptionLayer
//
//  A structured caption model: [Object] + [Context] + [Explanation].
//  Used as the on-device, non-destructive metadata payload written into iOS Photos.
//

import Foundation

/// Structured caption following the format:
/// `"[Object], [Context], [Explanation]"`
///
/// Example: `"Bronze ritual vessel, Shang dynasty, used in ceremonial offerings."`
///
/// Caption content is derived strictly from OCR text and/or user input.
/// The app never fabricates facts.
struct Caption: Codable, Equatable, Hashable {
    var object: String
    var context: String
    var explanation: String

    init(object: String = "", context: String = "", explanation: String = "") {
        self.object = object
        self.context = context
        self.explanation = explanation
    }

    /// Renders the caption as a single display string using the canonical format.
    var formatted: String {
        [object, context, explanation]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    /// `true` when every component is empty.
    var isEmpty: Bool {
        formatted.isEmpty
    }
}
