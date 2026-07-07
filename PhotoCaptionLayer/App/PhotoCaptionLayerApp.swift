//
//  PhotoCaptionLayerApp.swift
//  PhotoCaptionLayer
//
//  Entry point. Hosts the shared view model and the root navigation.
//

import SwiftUI

@main
struct PhotoCaptionLayerApp: App {
    @StateObject private var viewModel = EditorViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(viewModel)
                .task {
                    await viewModel.bootstrap()
                }
        }
    }
}

/// Top-level navigation container. Drives the Picker -> Editor -> Success flow.
struct RootView: View {
    @EnvironmentObject private var viewModel: EditorViewModel

    var body: some View {
        NavigationStack {
            PhotoPickerView()
                .navigationDestination(item: $viewModel.route) { route in
                    destination(for: route)
                }
        }
        .tint(.accentColor)
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .editor:
            EditorView()
        case .success:
            SuccessView()
        }
    }
}
