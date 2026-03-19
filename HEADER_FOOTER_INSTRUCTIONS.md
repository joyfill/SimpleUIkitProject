# Persistent Footer with Joyfill Validation (UIKit)

This guide explains how this example keeps a **custom gradient footer** visible at all times while the Joyfill form is shown—even when the SDK pushes table/collection modals or presents sheets. The pattern uses a second window that floats above the main content; only the footer is drawn there, and touches elsewhere pass through to the form.

---

## What This Example Does

- **Footer** at the **bottom**: two states — a **Submit button** (default) and a **validation bar** ("X of Y Completed" + up ↑ / down ↓ / close ✕).
- **Form** in the main window: uses `FormContainerViewController` (wraps `DocumentEditor` + Joyfill `Form` in a `UIHostingController`).
- **No header** in this project; the instructions below explain how to add one if needed.

---

## How It Works

1. **Two windows**
   - **Main window:** Your app window (`UINavigationController` → `FormsListViewController` → `SimpleFormContainerViewController`).
   - **Footer window:** A second `UIWindow` (`FooterPassthroughWindow`) with a higher `windowLevel` (`.statusBar`) so it draws on top. Its root view is clear; only the `GradientView` footer is drawn inside it.

2. **Touch passthrough**
   - `FooterPassthroughWindow` overrides `hitTest`: if the hit view is the root view (transparent background), it returns `nil` so the touch goes to the window below (the form). Touches on the footer hit those views, so they stay interactive.

3. **Self-managed footer window**
   - The footer window is created and destroyed entirely within `SimpleFormContainerViewController` via `attachFooterWindow()` / `detachFooterWindow()`. There is no global overlay reference in `SceneDelegate`.

4. **Reserving space**
   - `SimpleFormContainerViewController` sets `additionalSafeAreaInsets.bottom = footerContentHeight (56 pt)` in `viewDidLoad` so the form's scroll content isn't hidden behind the footer.

5. **Two footer states**
   - **State 1 — Submit**: a centered "Submit" button. Shown by default and after "close" (✕) is tapped.
   - **State 2 — Validation**: shows `"X of Y Completed"` label, up/down chevron buttons (navigate invalid fields), a separator, and a close (✕) button. Shown after Submit is tapped and `validate()` returns results.

---

## Project Structure (This Example)

| File | Role |
|------|------|
| **AppTheme** | `AppTheme` enum: gradient colors + `makeGradientImage()` for the nav bar. `FooterPassthroughWindow`: custom `UIWindow` whose `hitTest` passes touches through the root view. `GradientView`: `UIView` subclass that fills itself with the app gradient. |
| **SceneDelegate** | Creates the main window, applies gradient `UINavigationBarAppearance`, and sets `FormsListViewController` as root. No overlay window here. |
| **FormsListViewController** | `UITableView` list of forms. Tapping a row pushes `SimpleFormContainerViewController` with `formTitle` set. |
| **FormContainerViewController** | Takes a `JoyDoc` + optional page ID, creates `DocumentEditor`, and embeds `Form(documentEditor:)` via `UIHostingController`. Exposes `documentEditor` for the parent to use. |
| **SimpleFormContainerViewController** | Form screen: embeds `FormContainerViewController`, manages the `FooterPassthroughWindow` lifecycle, handles Submit → validate → navigate flow. Conforms to `FormChangeEvent` to keep the validation bar in sync as the user edits. |

---

## One Navigation Controller Is Enough

This project uses a **single `UINavigationController`** for the entire app — the one created in `SceneDelegate` that wraps `FormsListViewController`. There is no second or nested `UINavigationController` anywhere.

- `SimpleFormContainerViewController` is **pushed** onto that nav controller from `FormsListViewController`.
- `FormContainerViewController` is embedded inside `SimpleFormContainerViewController` as a **plain child view controller** (`addChild` / `didMove(toParent:)`), not wrapped in its own nav controller.
- The Joyfill SDK handles all **form-internal navigation** (opening table editors, presenting sheets, pushing collection views, etc.) by itself — it does not require a host nav controller to do so.

> **Why this matters:** wrapping the form in a nested `UINavigationController` is unnecessary and can interfere with how the SDK presents its own modals. Keep it simple: one nav controller at the app level, form as a direct child VC.

---

## Steps to Get the Same in Your App

### 1. App theme helpers (AppTheme.swift)

Add three things to a shared file:

- **`AppTheme`** enum with `gradientStart` / `gradientEnd` colors and `makeGradientImage()` (renders a 2×1 stretchable gradient `UIImage` for `UINavigationBarAppearance`).
- **`FooterPassthroughWindow`** — subclass `UIWindow`, override `hitTest` so touches on the root view pass through:

```swift
class FooterPassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit == rootViewController?.view ? nil : hit
    }
}
```

- **`GradientView`** — `UIView` subclass with a `CAGradientLayer` that fills its bounds using `AppTheme` colors.

### 2. SceneDelegate — main window only

In `scene(_:willConnectTo:options:)`:

- Create the main `UIWindow`, wrap your root view controller in a `UINavigationController`, apply gradient appearance, and call `makeKeyAndVisible()`.
- **No overlay window here** — the footer window is owned by the form screen.

```swift
let window = UIWindow(windowScene: windowScene)
let navController = UINavigationController(rootViewController: FormsListViewController())
applyGradientAppearance(to: navController)
window.rootViewController = navController
window.makeKeyAndVisible()
self.window = window
```

### 3. FormContainerViewController — form wrapper

- Accept a `JoyDoc` in `init`, create a `DocumentEditor`, and expose it publicly.
- In `viewDidLoad`, embed `Form(documentEditor: documentEditor)` in a `UIHostingController` and pin it to all four edges.

### 4. SimpleFormContainerViewController — form screen

#### 4a. Reserve space for the footer

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: footerContentHeight, right: 0)
    createFooterView()      // build the GradientView with both state containers
    setupFormNavigation()   // embed FormContainerViewController
}
```

#### 4b. Attach / detach the footer window

```swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    attachFooterWindow()
}

override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isMovingFromParent { detachFooterWindow() }
}
```

`attachFooterWindow()`:
- Guard against creating it twice and that `view.window?.windowScene` is available.
- Create `FooterPassthroughWindow(windowScene:)`, set `windowLevel = .statusBar`, clear background, `isHidden = false`.
- Set a plain `UIViewController` (clear background) as `rootViewController`.
- Add the pre-built `GradientView` (`footerView`) to the root VC's view, pinned to leading/trailing/bottom with a fixed height (e.g. 80 pt).

`detachFooterWindow()`: set `isHidden = true` and nil out the reference.

#### 4c. Build the footer view (two states)

Build the `GradientView` once in `createFooterView()`. Add two containers inside it:

| Container | Contents |
|-----------|----------|
| `submitContainer` | A centered "Submit" `UIButton` |
| `validationContainer` | `completedLabel` (leading), `upButton` ↑, `downButton` ↓, a hairline separator, `closeButton` ✕ (trailing) |

Both containers are pinned to `footerView.topAnchor` and fill the full width with height = `footerContentHeight (56 pt)`.

Toggle visibility via:
- `showSubmitState()` → `submitContainer.isHidden = false`, `validationContainer.isHidden = true`
- `showValidationState(completed:total:hasInvalid:)` → reverse; disable/dim up/down when no invalid fields

#### 4d. Submit → validate → navigate

```swift
@objc func submitTapped() {
    let validation = formVC.documentEditor.validate()
    fieldPaths = buildPaths(from: validation.fieldValidities)   // invalid field/row/cell paths
    currentFieldIndex = -1
    showValidationState(...)
}

@objc func downTapped() {
    currentFieldIndex = (currentFieldIndex + 1) % fieldPaths.count
    formVC.documentEditor.goto(fieldPaths[currentFieldIndex], gotoConfig: GotoConfig(focus: true))
}

@objc func upTapped() {
    currentFieldIndex = currentFieldIndex <= 0 ? fieldPaths.count - 1 : currentFieldIndex - 1
    formVC.documentEditor.goto(fieldPaths[currentFieldIndex], gotoConfig: GotoConfig(open: true, focus: true))
}

@objc func closeTapped() {
    fieldPaths = []; currentFieldIndex = -1
    showSubmitState()
}
```

**`buildPaths(from:)`** converts `[FieldValidity]` into a flat list of `"pageId/posId"`, `"pageId/posId/rowId"`, or `"pageId/posId/rowId/columnId"` strings (deepest invalid granularity first).

#### 4e. Keep validation bar in sync — FormChangeEvent

Conform to `FormChangeEvent` and implement `onChange(changes:document:)`:

```swift
func onChange(changes: [Change], document: JoyDoc) {
    DispatchQueue.main.async {
        guard !self.validationContainer.isHidden else { return }
        let validation = self.formVC.documentEditor.validate()
        self.fieldPaths = self.buildPaths(from: validation.fieldValidities)
        // clamp currentFieldIndex if paths shrank
        self.showValidationState(...)
    }
}
```

Set `formVC.documentEditor.events = self` after creating `FormContainerViewController`.

---

## Adding a Header (If You Only Have a Footer)

1. In **`SimpleFormContainerViewController`** (or a new header window class):
   - Add `headerWindow: FooterPassthroughWindow?` and a `UIView` (or `UIHostingController`) for the header.
   - In `attachFooterWindow()`, also create a header window and pin the header view to the top.
   - In `detachFooterWindow()`, also hide/nil the header window.

2. **Reserve space** at the top: update `additionalSafeAreaInsets` to include a `top` inset equal to the header height.

3. **Build a header SwiftUI view** (e.g. `NavigationControlsView`) that uses the same `DocumentEditor`:

```swift
overlayVC.setHeader(NavigationControlsView(documentEditor: formVC.documentEditor, onBack: {
    self.navigationController?.popViewController(animated: true)
}))
```

4. After layout (e.g. in a `DispatchQueue.main.async` block inside `viewDidAppear`), update the top inset from the actual header frame height.

---

## Checklist

- [ ] `FooterPassthroughWindow` created in the form screen's `viewDidAppear` with `windowLevel = .statusBar`.
- [ ] Root view controller of the footer window has a clear background; `GradientView` is pinned to the bottom with a fixed height.
- [ ] `additionalSafeAreaInsets.bottom` set in `viewDidLoad` so form content isn't hidden behind the footer.
- [ ] Footer window is hidden and nilled in `viewWillDisappear` (only when `isMovingFromParent`).
- [ ] `FormChangeEvent.onChange` updates the validation bar in sync with user edits.
- [ ] `buildPaths(from:)` drills down to the deepest invalid granularity (field → row → cell).

---

## Quick Reference: This Example's Flow

1. User taps a form in **FormsListViewController** → push **SimpleFormContainerViewController**.
2. **`viewDidLoad`**: sets `additionalSafeAreaInsets`, builds `footerView` (Submit state), embeds `FormContainerViewController`.
3. **`viewDidAppear`**: `attachFooterWindow()` creates `FooterPassthroughWindow` and moves `footerView` into it.
4. Footer shows **Submit** button. User fills the form.
5. User taps **Submit**: `validate()` runs, footer switches to validation bar ("X of Y Completed").
6. User taps ↑ / ↓: `documentEditor.goto(fieldPaths[index])` scrolls the form to the next/previous invalid field.
7. `onChange` fires on every field edit: validation bar updates live.
8. User taps ✕: footer returns to Submit state.
9. **`viewWillDisappear`** (back navigation): `detachFooterWindow()` removes the footer window.
