//
//  PhotoAnnotationView.swift
//  PhotoMap
//
//  UI layer — Custom MKAnnotationView showing photo thumbnail.
//  Enables clustering via clusteringIdentifier.
//

import MapKit
import UIKit

final class PhotoAnnotationView: MKAnnotationView {

    // MARK: - Constants

    static let reuseIdentifier = "PhotoAnnotationView"
    static let clusteringIdentifier = "PhotoCluster"

    private let imageSize: CGFloat = 44
    private let borderWidth: CGFloat = 2

    // MARK: - Initializer

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        clusteringIdentifier = Self.clusteringIdentifier
        collisionMode = .circle
        canShowCallout = true

        frame = CGRect(x: 0, y: 0, width: imageSize, height: imageSize)
        centerOffset = CGPoint(x: 0, y: -imageSize / 2)

        // Add detail disclosure button for callout
        let detailButton = UIButton(type: .detailDisclosure)
        rightCalloutAccessoryView = detailButton
    }

    // MARK: - Configuration

    override func prepareForReuse() {
        super.prepareForReuse()
        image = nil
    }

    override func prepareForDisplay() {
        super.prepareForDisplay()

        guard let photoAnnotation = annotation as? PhotoAnnotation else { return }

        // Create thumbnail from photo entry
        if let uiImage = UIImage(data: photoAnnotation.photoEntry.imageData) {
            image = createThumbnail(from: uiImage)
        } else {
            // Fallback to placeholder
            image = createPlaceholderImage()
        }

        // Add thumbnail to left callout
        if let uiImage = UIImage(data: photoAnnotation.photoEntry.imageData) {
            let thumbnailView = UIImageView(image: uiImage)
            thumbnailView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            thumbnailView.contentMode = .scaleAspectFill
            thumbnailView.clipsToBounds = true
            thumbnailView.layer.cornerRadius = 4
            leftCalloutAccessoryView = thumbnailView
        }
    }

    // MARK: - Image Creation

    private func createThumbnail(from image: UIImage) -> UIImage {
        let size = CGSize(width: imageSize, height: imageSize)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Draw white border circle
            UIColor.white.setFill()
            let borderRect = CGRect(origin: .zero, size: size)
            UIBezierPath(ovalIn: borderRect).fill()

            // Clip to circle for image
            let imageRect = borderRect.insetBy(dx: borderWidth, dy: borderWidth)
            let clipPath = UIBezierPath(ovalIn: imageRect)
            clipPath.addClip()

            // Draw scaled image
            image.draw(in: imageRect)
        }
    }

    private func createPlaceholderImage() -> UIImage {
        let size = CGSize(width: imageSize, height: imageSize)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Draw blue circle
            UIColor.systemBlue.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()

            // Draw camera icon
            let iconConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
            if let icon = UIImage(systemName: "photo.fill", withConfiguration: iconConfig) {
                icon.withTintColor(.white, renderingMode: .alwaysTemplate)
                    .draw(at: CGPoint(x: (size.width - icon.size.width) / 2,
                                      y: (size.height - icon.size.height) / 2))
            }
        }
    }
}
