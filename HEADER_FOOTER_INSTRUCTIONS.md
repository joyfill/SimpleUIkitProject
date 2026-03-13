# Persistent Header and Footer with Joyfill Form (UIKit)

This guide explains how this example keeps a **custom header** (and optionally a **footer**) visible at all times while the Joyfill form is shown—even when the SDK pushes table/collection modals or presents sheets. The pattern uses a second window that floats above the main content; only the header (and footer) are drawn there, and touches elsewhere pass through to the form.

---

## What This Example Does

- **Header** at the **top**: navigation controls (Back, Page/Field/Row/Column pickers, Navigate) in an overlay so they stay visible when the form pushes modals.
- **Form** in the main window: uses the same `DocumentEditor` as the header so “Navigate” and goto work.
- **No footer** in this project; the instructions below explain how to add one if needed.

---

## How It Works

1. **Two windows**
   - **Main window:** Your app window (e.g. `UINavigationController` → list → form).
   - **Overlay window:** A second `UIWindow` (`PassthroughWindow`) with a higher `windowLevel` (e.g. `.alert + 1`) so it draws on top. Its root view is clear; only the header (and footer) views are drawn.

2. **Touch passthrough**
   - `PassthroughWindow` overrides `hitTest`: if the hit view is the root view (transparent background), it returns `nil` so the touch goes to the window below (the form). Touches on the header/footer hit those views, so they stay interactive.

3. **Shared DocumentEditor**
   - The header (e.g. `NavigationControlsView`) and the form use the **same** `DocumentEditor`. The header calls `documentEditor.goto(...)` and the form reacts (scroll, open table, etc.).

4. **Reserving space**
   - The form screen adds a **header spacer** with the same height as the overlay header. The form is laid out below this spacer so its content isn’t covered.

5. **Optional: safe area on SDK modals**
   - When the SDK presents a modal, you can set `additionalSafeAreaInsets` on the presented view controller so its content doesn’t sit under the overlay header (and footer, if you add one).

---

## Project Structure (This Example)

| File | Role |
|------|------|
| **SceneDelegate** | Creates main window and overlay `PassthroughWindow` with `OverlayViewController`. Keeps references so the form screen can configure the overlay. |
| **PassthroughWindow** | Custom `UIWindow`; `hitTest` returns `nil` for the root view so touches pass through. |
| **OverlayViewController** | Clear root view; has `headerContainer` (top). `setHeader(_:)` hosts a SwiftUI view (e.g. `NavigationControlsView`). `showOverlay()` / `hideOverlay()` control visibility. |
| **SimpleFormContainerViewController** | Form screen: one `DocumentEditor`, header spacer, form in `UINavigationController`. In `viewDidAppear` configures overlay with header and updates spacer height; in `viewWillDisappear` hides overlay. Optionally injects safe area insets on presented modals. |
| **NavigationControlsView** | SwiftUI header: Back button (optional), Page/Field/Row/Column pickers, Navigate. Uses `documentEditor.goto(...)`. |
| **FormHostView** | Thin wrapper: `Form(documentEditor: documentEditor)` for use inside `UINavigationController`. |

---

## Steps to Get the Same in Your App

### 1. Overlay window in SceneDelegate

In `SceneDelegate.scene(_:willConnectTo:options:)`:

- Create the **main window** and set its root view controller (e.g. your navigation controller).
- Create the **overlay window** with your scene and a custom window class that passes touches through (step 2).
- Set overlay `windowLevel` higher than main (e.g. `.alert + 1`).
- Set overlay `rootViewController` to an overlay view controller that only hosts header (and optionally footer) containers (step 3).
- Store references to the overlay window and overlay view controller so your form screen can access them.

```swift
// Main window
let window = UIWindow(windowScene: windowScene)
window.rootViewController = yourNavController
window.makeKeyAndVisible()
self.window = window

// Overlay window
let overlay = PassthroughWindow(windowScene: windowScene)
overlay.windowLevel = .alert + 1
let overlayVC = OverlayViewController()
overlay.rootViewController = overlayVC
overlay.isHidden = false
overlayVC.hideOverlay()  // hidden until form screen appears

self.overlayWindow = overlay
self.overlayViewController = overlayVC
```

### 2. PassthroughWindow

Subclass `UIWindow` and override `hitTest` so touches on the root view pass through:

```swift
class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hit = super.hitTest(point, with: event) else { return nil }
        if hit === rootViewController?.view { return nil }
        return hit
    }
}
```

### 3. OverlayViewController

- Clear background.
- Add a container view for the **header** (e.g. pinned to safe area top, leading, trailing).
- Optionally add a **footer** container (e.g. pinned to safe area bottom, leading, trailing).
- Expose `setHeader(_:)` (and `setFooter(_:)` if you use a footer) to add a SwiftUI view via `UIHostingController` into the right container and pin it to the container’s edges.
- Expose `showOverlay()` and `hideOverlay()` to show/hide both containers.

Host the SwiftUI view with `UIHostingController` and set the host view’s background to clear.

### 4. Form screen (your form container)

- Create **one** `DocumentEditor` and keep it.
- Add a **header spacer** at the top (height updated after overlay layout; see below).
- If you use a footer, add a **footer spacer** at the bottom.
- Lay out the **form** (e.g. in a `UINavigationController`) between the spacers: form’s top = header spacer bottom, form’s bottom = footer spacer top (or view bottom if no footer).
- In **viewDidAppear**:
  - Get the overlay view controller from the scene (e.g. `view.window?.windowScene?.delegate as? SceneDelegate` → `overlayViewController`).
  - Build your header SwiftUI view with the **same** `documentEditor` (and optional `onBack` or other callbacks).
  - Call `overlayVC.setHeader(yourHeaderView)` (and `setFooter` if you have a footer).
  - Call `overlayVC.showOverlay()`.
  - After layout (e.g. `DispatchQueue.main.async`), set the header spacer height from `overlayVC.headerContainer.frame.height` (and footer spacer from `footerContainer` if used).
- In **viewWillDisappear**: call `overlayVC.hideOverlay()`.

### 5. Optional: safe area on SDK-presented modals

So that SDK-presented modals don’t sit under the overlay:

- When the form screen is on screen, run a timer or observer that finds the **presented** view controller (from your form’s nav controller or hosting controller).
- Set that VC’s `additionalSafeAreaInsets`: e.g. `top = header height`, `bottom = footer height` (or 0 if no footer).
- Skip or adjust for popovers if needed (`modalPresentationStyle != .popover`).

---

## Adding a Footer (If You Only Have a Header)

1. In **OverlayViewController**:
   - Add `footerContainer` and pin it to the bottom (e.g. `view.safeAreaLayoutGuide.bottomAnchor` or `view.bottomAnchor`).
   - Add `setFooter(_ swiftUIView: some View)` that hosts the SwiftUI view in `footerContainer` (same pattern as `setHeader`).
   - In `showOverlay()` / `hideOverlay()`, show/hide `footerContainer` as well.

2. In your **form screen**:
   - Add a **footer spacer** view at the bottom and pin the form above it.
   - After layout, set the footer spacer height from `overlayVC.footerContainer.frame.height`.
   - When injecting safe area on presented modals, set `bottom` inset to the footer height.

3. Build a SwiftUI **footer view** (e.g. navigator bar or action buttons) that uses the same `DocumentEditor` if needed, and pass it to `setFooter(_:)` in `configureOverlay()`.

---

## Checklist

- [ ] Overlay window (PassthroughWindow) created in scene delegate with higher `windowLevel`.
- [ ] Overlay view controller with at least a header container and `setHeader`; add footer container and `setFooter` if you want a footer.
- [ ] Form screen uses one `DocumentEditor` and passes it to both the form and the header (and footer) view.
- [ ] Header (and footer) spacers in the form screen match overlay heights so form content isn’t covered.
- [ ] Show overlay in `viewDidAppear` of the form screen; hide in `viewWillDisappear`.
- [ ] (Optional) Set `additionalSafeAreaInsets` on SDK-presented modals so they avoid the overlay.

---

## Quick Reference: This Example’s Flow

1. User taps a form in **FormsListViewController** → push **SimpleFormContainerViewController**.
2. **SimpleFormContainerViewController** loads document, creates **DocumentEditor**, sets up form and header spacer.
3. On **viewDidAppear**: gets **OverlayViewController** from **SceneDelegate**, sets header to **NavigationControlsView(documentEditor:onBack:)** (onBack pops the form screen), calls **showOverlay()**, then updates header spacer height.
4. Header stays on top (overlay window); form scrolls and pushes modals in the main window. Back and Navigate work via shared **DocumentEditor** and onBack.
5. On **viewWillDisappear**: **hideOverlay()** so the header disappears when leaving the form.

Use this flow and the steps above to achieve the same persistent header (and optional footer) in your own app.
