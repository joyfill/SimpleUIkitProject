//
//  SimpleFormContainerViewController.swift
//  SimpleUIkitProject
//
//  Navigation header (path + dropdowns) + Form using Navigation.json.
//  The header is hosted in a PassthroughWindow overlay so it remains
//  visible even when the Joyfill SDK presents a fullscreen modal.
//  The Form lives in the main window and shares the same DocumentEditor instance
//  with the navigation controls in the overlay.
//

import UIKit
import SwiftUI
import Joyfill
import JoyfillModel

class SimpleFormContainerViewController: UIViewController {

    private var documentEditor: DocumentEditor!
    private var formHostingController: UIHostingController<FormHostView>!
    private var formNavController: UINavigationController!
    private var overlayConfigured = false

    /// Spacer view that reserves space for the overlay header.
    private let headerSpacer = UIView()

    /// Observation token for detecting SDK-presented modals.
    private var presentationObserver: Any?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let document = loadNavigationDocument()
        documentEditor = DocumentEditor(
            document: document,
            mode: .fill,
            validateSchema: false,
            license: nil,
            singleClickRowEdit: true
        )

        setupForm()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the parent nav bar — the overlay header replaces it
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !overlayConfigured {
            configureOverlay()
            overlayConfigured = true
        }
        overlayVC?.showOverlay()
        startObservingPresentedModals()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        overlayVC?.hideOverlay()
        stopObservingPresentedModals()
    }

    // MARK: - Overlay (header in PassthroughWindow)

    private var overlayVC: OverlayViewController? {
        guard let scene = view.window?.windowScene,
              let sceneDelegate = scene.delegate as? SceneDelegate else { return nil }
        return sceneDelegate.overlayViewController
    }

    private func configureOverlay() {
        guard let overlayVC = overlayVC else { return }

        // Navigation controls header — shares the same documentEditor as the form
        let controlsView = NavigationControlsView(documentEditor: documentEditor, onBack: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
        overlayVC.setHeader(controlsView)

        overlayVC.showOverlay()

        // Wait one layout pass so the header's intrinsic size is known
        DispatchQueue.main.async { [weak self] in
            self?.updateHeaderSpacerHeight()
        }
    }

    // MARK: - Form

    private func setupForm() {
        // Header spacer — reserves vertical space; actual height set after overlay layout
        headerSpacer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerSpacer)

        // Form inside UIKit navigation controller (no SwiftUI NavigationView/NavigationStack)
        let formView = FormHostView(documentEditor: documentEditor)
        formHostingController = UIHostingController(rootView: formView)
        formNavController = UINavigationController(rootViewController: formHostingController)

        formNavController.setNavigationBarHidden(true, animated: false)
        formNavController.delegate = self
        addChild(formNavController)
        formNavController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(formNavController.view)
        formNavController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            // Header spacer at top
            headerSpacer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerSpacer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerSpacer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerSpacer.heightAnchor.constraint(equalToConstant: 0), // updated after overlay layout

            // Form nav between header spacer and bottom
            formNavController.view.topAnchor.constraint(equalTo: headerSpacer.bottomAnchor),
            formNavController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            formNavController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            formNavController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    /// Called after overlay layout to match the header spacer height to the actual overlay header.
    private func updateHeaderSpacerHeight() {
        guard let overlayVC = overlayVC else { return }
        overlayVC.view.layoutIfNeeded()
        let headerHeight = overlayVC.headerContainer.frame.height
        for constraint in headerSpacer.constraints where constraint.firstAttribute == .height {
            constraint.constant = headerHeight
        }
        view.layoutIfNeeded()
    }

    // MARK: - Modal presentation observer
    //
    // The Joyfill SDK presents a fullscreen modal (SwiftUI .sheet/.fullScreenCover)
    // for row editing.  We inject additionalSafeAreaInsets on the presented VC so
    // its content avoids the overlay header.

    private func startObservingPresentedModals() {
        // Check periodically for newly presented modals
        presentationObserver = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.injectSafeAreaInsetsOnPresentedModal()
        }
    }

    private func stopObservingPresentedModals() {
        (presentationObserver as? Timer)?.invalidate()
        presentationObserver = nil
    }

    private func injectSafeAreaInsetsOnPresentedModal() {
        guard let overlayVC = overlayVC else { return }
        let headerHeight = overlayVC.headerContainer.frame.height
        let insets = UIEdgeInsets(top: headerHeight, left: 0, bottom: 0, right: 0)

        // Walk the presentation chain from the form nav controller
        var presented = formNavController?.presentedViewController
        while let vc = presented {
            // Skip popovers — they are small floating views that don't need extra insets
            if vc.modalPresentationStyle != .popover {
                if vc.additionalSafeAreaInsets != insets {
                    vc.additionalSafeAreaInsets = insets
                }
            }
            presented = vc.presentedViewController
        }
    }

    // MARK: - Helpers

    private func loadNavigationDocument() -> JoyDoc {
        guard let path = Bundle.main.path(forResource: "Navigation", ofType: "json") else {
            fatalError("Navigation.json not found in bundle. Add it to the project.")
        }
        let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let dict = try! JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as! [String: Any]
        return JoyDoc(dictionary: dict)
    }
}
// MARK: - UINavigationControllerDelegate

extension SimpleFormContainerViewController: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        // Hide the nav bar only on the root (form) screen; show it on pushed screens (e.g. table detail)
        let isRoot = viewController === formHostingController
        navigationController.setNavigationBarHidden(isRoot, animated: animated)
    }
}

/// Wrapper so the form can be hosted in a UINavigationController without SwiftUI NavigationView.
struct FormHostView: View {
    @ObservedObject var documentEditor: DocumentEditor
    var body: some View {
        Form(documentEditor: documentEditor)
    }
}
