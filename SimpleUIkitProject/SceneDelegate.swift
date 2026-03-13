//
//  SceneDelegate.swift
//  SimpleUIkitProject
//
//  Created by Vivek on 12/03/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    /// Overlay window that floats above modals for header/footer.
    private(set) var overlayWindow: PassthroughWindow?
    private(set) var overlayViewController: OverlayViewController?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Main window
        let window = UIWindow(windowScene: windowScene)
        let navController = UINavigationController(rootViewController: FormsListViewController())
        window.rootViewController = navController
        window.makeKeyAndVisible()
        self.window = window

        // Overlay window – sits above all modals
        let overlay = PassthroughWindow(windowScene: windowScene)
        overlay.windowLevel = .alert + 1
        let overlayVC = OverlayViewController()
        overlay.rootViewController = overlayVC
        overlay.isHidden = false
        overlayVC.hideOverlay() // hidden until a form screen activates it
        self.overlayWindow = overlay
        self.overlayViewController = overlayVC
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}

