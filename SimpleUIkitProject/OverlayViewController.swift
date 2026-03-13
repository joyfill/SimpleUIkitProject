//
//  OverlayViewController.swift
//  SimpleUIkitProject
//
//  Hosts header and footer bars in the PassthroughWindow overlay.
//  The root view is transparent so touches pass through everywhere
//  except on the header/footer themselves.
//

import UIKit
import SwiftUI
import JoyfillModel

class OverlayViewController: UIViewController {

    let headerContainer = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerContainer)

        NSLayoutConstraint.activate([
            // Header pinned to top safe area
            headerContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    // MARK: - Header

    func setHeader(_ swiftUIView: some View) {
        // Remove any previous header content
        headerContainer.subviews.forEach { $0.removeFromSuperview() }
        children.filter { $0.view.superview === headerContainer }.forEach {
            $0.willMove(toParent: nil)
            $0.removeFromParent()
        }

        let host = UIHostingController(rootView: AnyView(swiftUIView))
        host.view.backgroundColor = .clear
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(host.view)
        host.didMove(toParent: self)

        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),
        ])
    }

    // MARK: - Show / Hide

    func showOverlay() {
        headerContainer.isHidden = false
    }

    func hideOverlay() {
        headerContainer.isHidden = true
    }
}
