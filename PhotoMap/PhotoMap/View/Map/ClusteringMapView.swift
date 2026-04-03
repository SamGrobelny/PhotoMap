//
//  ClusteringMapView.swift
//  PhotoMap
//
//  UI layer — UIViewRepresentable wrapping MKMapView with photo clustering.
//  Displays photo annotations with automatic clustering when zoomed out.
//

import SwiftUI
import MapKit

struct ClusteringMapView: UIViewRepresentable {

    // MARK: - Properties

    let entries: [PhotoEntry]
    let onAnnotationSelected: (PhotoEntry) -> Void

    @Binding var region: MKCoordinateRegion

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        // Register custom annotation views
        mapView.register(
            PhotoAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: PhotoAnnotationView.reuseIdentifier
        )
        mapView.register(
            ClusterAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: ClusterAnnotationView.reuseIdentifier
        )

        // Set initial region
        mapView.setRegion(region, animated: false)

        // Enable user location if authorized
        mapView.showsUserLocation = true

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        updateAnnotations(on: mapView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - Annotation Management

    private func updateAnnotations(on mapView: MKMapView) {
        // Get current photo annotations (excluding user location)
        let currentAnnotations = mapView.annotations.compactMap { $0 as? PhotoAnnotation }
        let currentEntryIDs = Set(currentAnnotations.map { $0.photoEntry.id })
        let newEntryIDs = Set(entries.map { $0.id })

        // Remove annotations for entries that no longer exist
        let annotationsToRemove = currentAnnotations.filter { !newEntryIDs.contains($0.photoEntry.id) }
        mapView.removeAnnotations(annotationsToRemove)

        // Add annotations for new entries
        let entriesToAdd = entries.filter { !currentEntryIDs.contains($0.id) }
        let annotationsToAdd = entriesToAdd.map { PhotoAnnotation(photoEntry: $0) }
        mapView.addAnnotations(annotationsToAdd)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, MKMapViewDelegate {

        let parent: ClusteringMapView

        init(parent: ClusteringMapView) {
            self.parent = parent
        }

        // MARK: - MKMapViewDelegate

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Don't customize user location
            if annotation is MKUserLocation {
                return nil
            }

            // Handle cluster annotations
            if let cluster = annotation as? MKClusterAnnotation {
                return mapView.dequeueReusableAnnotationView(
                    withIdentifier: ClusterAnnotationView.reuseIdentifier,
                    for: cluster
                )
            }

            // Handle photo annotations
            if let photoAnnotation = annotation as? PhotoAnnotation {
                return mapView.dequeueReusableAnnotationView(
                    withIdentifier: PhotoAnnotationView.reuseIdentifier,
                    for: photoAnnotation
                )
            }

            return nil
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            // Handle cluster tap - zoom to show members
            if let cluster = view.annotation as? MKClusterAnnotation {
                let memberAnnotations = cluster.memberAnnotations
                mapView.showAnnotations(memberAnnotations, animated: true)
                mapView.deselectAnnotation(cluster, animated: false)
                return
            }
        }

        func mapView(
            _ mapView: MKMapView,
            annotationView view: MKAnnotationView,
            calloutAccessoryControlTapped control: UIControl
        ) {
            // Handle detail disclosure tap for photo annotation
            if let photoAnnotation = view.annotation as? PhotoAnnotation {
                parent.onAnnotationSelected(photoAnnotation.photoEntry)
            }
        }

        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            // Update binding when user moves the map
            DispatchQueue.main.async {
                self.parent.region = mapView.region
            }
        }
    }
}
