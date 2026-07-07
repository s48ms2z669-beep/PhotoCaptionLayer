//
//  CaptionFieldView.swift
//  PhotoCaptionLayer
//
//  Editable structured caption fields: Object, Context, Explanation.
//  Bound directly to the view model's `caption` so user edits are preserved.
//

import SwiftUI

struct CaptionFieldView: View {
    @Binding var caption: Caption

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            field(
                title: "Object",
                hint: "What is it? e.g. Bronze ritual vessel",
                text: $caption.object
            )
            field(
                title: "Context",
                hint: "Where / when / what kind? e.g. Shang dynasty",
                text: $caption.context
            )
            field(
                title: "Explanation",
                hint: "Why does it matter? e.g. used in ceremonial offerings",
                text: $caption.explanation,
                axis: .vertical
            )
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func field(
        title: String,
        hint: String,
        text: Binding<String>,
        axis: Axis = .horizontal
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            if axis == .vertical {
                TextField(hint, text: text, axis: axis)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
            } else {
                TextField(hint, text: text, axis: axis)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1)
            }
        }
    }
}
