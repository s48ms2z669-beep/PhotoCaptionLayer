//
//  SuccessView.swift
//  PhotoCaptionLayer
//
//  Screen 3 — Success.
//  Confirmation that the caption was written, plus a button to return to the
//  picker to enhance more photos.
//

import SwiftUI

struct SuccessView: View {
    @EnvironmentObject private var viewModel: EditorViewModel

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: true)

            VStack(spacing: 10) {
                Text("Caption Saved")
                    .font(.title2.weight(.bold))
                Text("The caption has been saved to photo 1 as non-destructive app metadata. It can be read by PhotoCaptionLayer when the same photo is opened again.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("What was written")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(viewModel.caption.formatted)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)

            VStack(spacing: 10) {
                Label(
                    "System Photos may show this image as edited, but it will not display the custom caption in the Info panel. Later edits from Photos or other apps may overwrite this app metadata.",
                    systemImage: "info.circle"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            }

            Spacer()

            Button {
                viewModel.resetToPicker()
            } label: {
                Label("Enhance Another Photo Group", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .navigationBarBackButtonHidden(true)
    }
}
