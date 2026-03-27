//
//  AppTheme.swift
//  SimpleUIkitProject
//

import UIKit

// MARK: - AppTheme
// Single source of truth for the app's gradient colors

enum AppTheme {
    static let gradientStart = UIColor(red: 0.20, green: 0.45, blue: 0.90, alpha: 1)
    static let gradientEnd   = UIColor(red: 0.10, green: 0.25, blue: 0.72, alpha: 1)

    /// Renders the gradient as a stretchable UIImage for use in UINavigationBarAppearance
    static func makeGradientImage() -> UIImage {
        let size = CGSize(width: 2, height: 1)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let colors = [gradientStart.cgColor, gradientEnd.cgColor] as CFArray
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0, 1]
            )!
            ctx.cgContext.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: size.width, y: 0),
                options: []
            )
        }.resizableImage(withCapInsets: .zero, resizingMode: .stretch)
    }
}
