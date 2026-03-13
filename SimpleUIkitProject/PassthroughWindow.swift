//
//  PassthroughWindow.swift
//  SimpleUIkitProject
//
//  A UIWindow subclass that passes touches through to the window below,
//  except when the touch lands on a visible subview (header/footer bars).
//

import UIKit

class PassthroughWindow: UIWindow {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hit = super.hitTest(point, with: event) else { return nil }
        // If the hit view is the root view itself (the transparent background),
        // return nil so the touch falls through to the main window.
        if hit === rootViewController?.view {
            return nil
        }
        return hit
    }
}
