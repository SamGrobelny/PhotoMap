//
//  ClusterAnnotationView.swift
//  PhotoMap
//
//  UI layer — Custom MKAnnotationView for clustered photo annotations.
//  Shows count badge with color scaling based on cluster size.
//

import MapKit
import UIKit

final class ClusterAnnotationView: MKAnnotationView {

    // MARK: - Constants

    static let reuseIdentifier = "ClusterAnnotationView"

    private let baseSize: CGFloat = 40
    private let maxSize: CGFloat = 56

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
        collisionMode = .circle
        canShowCallout = true
    }

    // MARK: - Configuration

    override func prepareForReuse() {
        super.prepareForReuse()
        image = nil
    }

    override func prepareForDisplay() {
        super.prepareForDisplay()

        guard let cluster = annotation as? MKClusterAnnotation else { return }

        let count = cluster.memberAnnotations.count
        let (color, size) = appearanceForCount(count)

        image = createClusterImage(count: count, color: color, size: size)
        frame = CGRect(x: 0, y: 0, width: size, height: size)
        centerOffset = CGPoint(x: 0, y: -size / 2)

        // Update callout subtitle
        displayPriority = .defaultHigh
    }

    // MARK: - Appearance Logic

    private func appearanceForCount(_ count: Int) -> (UIColor, CGFloat) {
        switch count {
        case ..<20:
            return (UIColor.systemBlue, baseSize)
        case 20..<50:
            return (UIColor.systemOrange, baseSize + 8)
        default:
            return (UIColor.systemRed, maxSize)
        }
    }

    // MARK: - Image Creation

    private func createClusterImage(count: Int, color: UIColor, size: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))

        return renderer.image { context in
            // Draw outer circle with shadow effect
            let shadowColor = color.withAlphaComponent(0.3)
            shadowColor.setFill()
            UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size)).fill()

            // Draw main circle
            color.setFill()
            let mainCircle = CGRect(x: 2, y: 2, width: size - 4, height: size - 4)
            UIBezierPath(ovalIn: mainCircle).fill()

            // Draw white inner circle
            UIColor.white.setFill()
            let innerCircle = mainCircle.insetBy(dx: 3, dy: 3)
            UIBezierPath(ovalIn: innerCircle).fill()

            // Draw count text
            let text = formatCount(count)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize(for: count), weight: .bold),
                .foregroundColor: color
            ]

            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size - textSize.width) / 2,
                y: (size - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            text.draw(in: textRect, withAttributes: attributes)
        }
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return "\(count / 1000)k+"
        } else if count >= 100 {
            return "\(count)"
        } else {
            return "\(count)"
        }
    }

    private func fontSize(for count: Int) -> CGFloat {
        switch count {
        case ..<100:
            return 14
        case 100..<1000:
            return 12
        default:
            return 10
        }
    }
}
