//
//  PhotoListScreen.swift
//  PhotoMap
//
//  UI layer — shows all stored photo entries.
//  Demonstrates Read, Update (edit caption), and Delete CRUD operations.
//

import SwiftUI

struct PhotoListScreen: View {

    @ObservedObject var viewModel: MapViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.entries) { entry in
                    NavigationLink {
                        PhotoDetailScreen(entry: entry, viewModel: viewModel)
                    } label: {
                        PhotoEntryRow(entry: entry)
                    }
                }
                .onDelete { offsets in
                    viewModel.deleteEntries(at: offsets)
                }
            }
            .navigationTitle("My Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            .overlay {
                if viewModel.entries.isEmpty {
                    ContentUnavailableView(
                        "No Photos Yet",
                        systemImage: "photo.badge.plus",
                        description: Text("Tap + on the map to add your first photo pin.")
                    )
                }
            }
        }
    }
}

// MARK: - Row

private struct PhotoEntryRow: View {
    let entry: PhotoEntry

    var body: some View {
        HStack(spacing: 12) {
            if let uiImage = UIImage(data: entry.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.caption.isEmpty ? "No caption" : entry.caption)
                    .font(.headline)
                    .lineLimit(1)

                Text(String(format: "%.4f, %.4f", entry.latitude, entry.longitude))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(entry.timestamp, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
