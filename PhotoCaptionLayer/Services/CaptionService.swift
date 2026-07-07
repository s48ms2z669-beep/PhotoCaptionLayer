//
//  CaptionService.swift
//  PhotoCaptionLayer
//
//  Builds a structured `Caption` from OCR text and/or user input.
//
//  CAPTION RULES
//  --------------
//  • Never hallucinate facts.
//  • Priority: User input > OCR > AI (AI is optional and lowest priority).
//  • Format: "[Object], [Context], [Explanation]".
//    Example: "Bronze ritual vessel, Shang dynasty, used in ceremonial offerings."
//
//  This implementation is heuristic and strictly grounded: it only reshapes
//  text that already exists in the OCR output or user input. It invents nothing.
//

import Foundation

final class CaptionService {
    static let shared = CaptionService()
    private init() {}

    /// Builds a caption honouring the priority order:
    /// user input > OCR > AI (none).
    ///
    /// - Parameters:
    ///   - ocrText: Cleaned, newline-joined OCR output (may be empty).
    ///   - userInput: Optional free-text the user typed (highest priority).
    /// - Returns: A structured `Caption`.
    func buildCaption(from ocrText: String, userInput: String? = nil) -> Caption {
        let cleanedOCR = clean(ocrText)
        let trimmedInput = (userInput ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        // Highest priority: explicit user input is treated as the Object line.
        // Remaining OCR (if any) supplies Context.
        if !trimmedInput.isEmpty {
            let object = trimmedInput
            let context = cleanedOCR.isEmpty ? "" : summarized(cleanedOCR)
            return Caption(object: object, context: context, explanation: "")
        }

        // OCR-only path. Use a lightweight heuristic to split signage text into
        // an object line (first meaningful line) and the remainder as context.
        if !cleanedOCR.isEmpty {
            let lines = cleanedOCR.split(separator: "\n", omittingEmptySubsequences: true)
                .map { String($0) }
            let object = lines.first ?? ""
            let context = lines.dropFirst().joined(separator: " ")
            return Caption(object: object, context: context, explanation: "")
        }

        // No OCR and no user input: leave empty. The app never invents content.
        return Caption(object: "", context: "", explanation: "")
    }

    // MARK: - Text hygiene

    /// Collapses whitespace, drops empty lines, and removes duplicate lines
    /// that commonly appear when a sign is photographed twice in one shot.
    private func clean(_ text: String) -> String {
        let seen = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var unique: [String] = []
        for line in seen where !unique.contains(line) {
            unique.append(line)
        }
        return unique.joined(separator: "\n")
    }

    /// Produces a compact single-line summary of multi-line OCR for the Context
    /// field, without rephrasing meaning.
    private func summarized(_ text: String) -> String {
        text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
