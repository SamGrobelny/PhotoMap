//
//  PhotoDetailScreen.swift
//  PhotoMap
//
//  UI layer — Detail view for a single photo entry.
//  Demonstrates UPDATE and DELETE CRUD operations.
//

import SwiftUI

struct PhotoDetailScreen: View {

    let entry: PhotoEntry
    @ObservedObject var viewModel: MapViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var editedCaption: String = ""
    @State private var isEditing: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Photo
                if let uiImage = UIImage(data: entry.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 4)
                }

                // Caption (editable)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Caption")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    if isEditing {
                        TextField("Enter caption...", text: $editedCaption, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    } else {
                        Text(entry.caption.isEmpty ? "No caption" : entry.caption)
                            .font(.body)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                // Metadata
                VStack(spacing: 12) {
                    MetadataRow(label: "Latitude", value: String(format: "%.6f", entry.latitude))
                    MetadataRow(label: "Longitude", value: String(format: "%.6f", entry.longitude))
                    MetadataRow(label: "Date", value: entry.timestamp.formatted(date: .long, time: .shortened))

                    if let altitude = entry.altitude {
                        MetadataRow(label: "Altitude", value: String(format: "%.1f m", altitude))
                    }

                    if let filename = entry.originalFilename {
                        MetadataRow(label: "Filename", value: filename)
                    }

                    if let device = entry.deviceModel {
                        MetadataRow(label: "Device", value: device)
                    }
                }

                Spacer(minLength: 40)

                // Delete button
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Photo", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding()
        }
        .navigationTitle("Photo Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        // Save changes
                        viewModel.updateCaption(for: entry, newCaption: editedCaption)
                    } else {
                        // Enter edit mode
                        editedCaption = entry.caption
                    }
                    isEditing.toggle()
                }
            }
        }
        .alert("Delete Photo?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteEntry(entry)
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .onAppear {
            editedCaption = entry.caption
        }
    }
}

// MARK: - Metadata Row

private struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
