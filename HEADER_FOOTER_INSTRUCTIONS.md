# Persistent Footer with Joyfill Validation (UIKit + SwiftUI)

This guide explains how this example implements a **gradient footer** with **Submit** and **validation navigation** while the Joyfill form is shown. The footer is built with SwiftUI and attached through Joyfill’s **`formFooter`** API on `Form`, so it stays part of the form’s layout (no separate overlay `UIWindow`).

---

## What This Example Does

- **Footer** at the **bottom**: two states — a **Submit** button (default) and a **validation bar** (“X of Y Completed” + up ↑ / down ↓ / close ✕).
- **Form** in `FormContainerViewController`: `DocumentEditor` + Joyfill `Form` in a `UIHostingController`, with `.formFooter { SampleFormFooterBar(...) }`.
- **Page-aware visibility**: the footer is intended for a **default page** (the first page in the document for this sample). When the user focuses another page, the footer can hide; when they return to that page, it shows again (`onFocus` / `onBlur` on `SampleFormFooterController`).
- **No separate header** in this project; you can add UIKit/SwiftUI chrome above the form the same way you embed `FormContainerViewController`.

---

## How It Works

1. **`Form` + `formFooter`**
   - `FormContainerViewController` exposes a SwiftUI `joyFillView` that wraps `Form(documentEditor:)` and uses `.formFooter { SampleFormFooterBar(controller: footerController) }`.
   - Joyfill lays out the footer below the form content, so it scrolls and behaves with the form instead of requiring a second window.

2. **`SampleFormFooterController`**
   - `ObservableObject` that also conforms to **`FormChangeEvent`** and is set as `documentEditor.events`.
   - Holds weak `documentEditor`, published state (`showValidationBar`, `completedText`, `navigationEnabled`, `isFooterVisible`), and implements **Submit → validate → ↑/↓ goto → close**, plus **live validation** in `onChange`.
   - **`configureFooterVisibility(visibleOnPageID:initialPageID:)`** ties the footer to a page ID (from `FormContainerViewController.defaultFooterPageID`). **`onFocus`** / **`onBlur`** update whether the bar is visible when the user switches pages.

3. **`SampleFormFooterBar`**
   - SwiftUI view that reads the controller’s published state, draws the same **AppTheme** linear gradient as the navigation bar, and shows either Submit or the validation row (min height 56 pt).

4. **`SimpleFormContainerViewController`**
   - List → detail screen only: sets the nav **title**, loads **`Validation.json`** into a `JoyDoc`, and embeds **`FormContainerViewController`** full screen. It does **not** own the footer; all footer logic lives in `FormContainerViewController` + `SampleFormFooter.swift`.

5. **Single navigation stack**
   - One `UINavigationController` in `SceneDelegate` → `FormsListViewController` → push `SimpleFormContainerViewController`.
   - `FormContainerViewController` is a **child** of `SimpleFormContainerViewController` (`addChild` / constraints), not wrapped in a nested `UINavigationController`. Joyfill handles in-form navigation (tables, sheets, etc.) internally.

---

## Project Structure (This Example)

| File | Role |
|------|------|
| **AppTheme** | `AppTheme` enum: `gradientStart` / `gradientEnd` and `makeGradientImage()` for the nav bar (and matching gradient in `SampleFormFooterBar`). |
| **SceneDelegate** | Main `UIWindow`, `UINavigationController` root = `FormsListViewController`, gradient `UINavigationBarAppearance`. |
| **FormsListViewController** | Table of forms; pushing `SimpleFormContainerViewController` with `formTitle` set. |
| **SimpleFormContainerViewController** | Embeds `FormContainerViewController`; loads `Validation.json`. |
| **FormContainerViewController** | Creates `DocumentEditor`, `UIHostingController` for `Form` + `formFooter`, owns `SampleFormFooterController`, wires `events` and footer page visibility. |
| **SampleFormFooter.swift** | `SampleFormFooterController` (validation, navigation, `FormChangeEvent`) + `SampleFormFooterBar` (SwiftUI UI). |

---

## Steps to Reproduce the Pattern in Your App

### 1. Shared theme (`AppTheme.swift`)

Use a small enum with gradient colors and `makeGradientImage()` for `UINavigationBarAppearance`, and reuse the same colors in the footer gradient (see `SampleFormFooterBar`).

### 2. `SceneDelegate` — one main window

Create the window, set root to your nav controller, apply bar appearance, `makeKeyAndVisible()`. No extra windows for the footer.

### 3. Footer controller (`SampleFormFooterController`)

- Keep references to `DocumentEditor`, optional `footerPageID`, `fieldPaths`, `currentFieldIndex`.
- **`submitTapped()`**: `documentEditor.validate()`, `buildPaths` from invalid `FieldValidity` entries, set `completedText`, `navigationEnabled`, `showValidationBar = true`.
- **`upTapped()` / `downTapped()`**: cycle `currentFieldIndex`, call `documentEditor.goto(_:gotoConfig:)` with `GotoConfig(open: true, focus: true)` (this sample uses the same config for both).
- **`closeTapped()`**: clear paths and `showValidationBar = false`.
- **`onChange`**: if `showValidationBar`, re-validate, refresh paths and labels, clamp `currentFieldIndex`.
- **`onFocus` / `onBlur`**: call `updateFooterVisibility` so the footer shows only on the page you care about (optional).

### 4. Footer SwiftUI (`SampleFormFooterBar`)

- Observe the controller; if `isFooterVisible`, show either Submit or validation content inside a `LinearGradient` background (min height 56).
- Wire buttons to `submitTapped`, `upTapped`, `downTapped`, `closeTapped`; disable/dim ↑↓ when `navigationEnabled` is false.

### 5. `FormContainerViewController`

- Create `DocumentEditor` with your `JoyDoc` and options as needed.
- Instantiate `SampleFormFooterController`, set `documentEditor.events = footerController`, `footerController.documentEditor = documentEditor`, then `configureFooterVisibility(visibleOnPageID:initialPageID:)`.
- In `joyFillView`, use `Form(documentEditor:).formFooter { SampleFormFooterBar(controller: footerController) }`.
- Embed that SwiftUI tree in `UIHostingController` and pin it to the container’s view.

### 6. Host view controller

- Push or present a screen that only embeds `FormContainerViewController` (like `SimpleFormContainerViewController`). No `additionalSafeAreaInsets` workaround is required for the footer when using `formFooter`—Joyfill accounts for the footer region.

---

## Adding a Header (Optional)

If you need a fixed header **outside** Joyfill’s form:

- Add a header view or `UIHostingController` **above** the `FormContainerViewController`’s view in your parent VC, or use Joyfill’s APIs if your SDK version exposes header/toolbar slots.
- Adjust constraints so the form hosting view sits below the header; reserve top safe area or fixed height as needed.

The old pattern of a second `UIWindow` for a footer is **not** used in this sample anymore.

---

## Checklist

- [ ] `Form` uses `.formFooter { ... }` with your SwiftUI bar.
- [ ] `SampleFormFooterController` (or equivalent) is `documentEditor.events` and implements `FormChangeEvent` for `onChange` (and optionally `onFocus` / `onBlur`).
- [ ] Submit runs `validate()`; invalid paths are built with deepest granularity (field → row → cell) in `buildPaths`.
- [ ] ↑ / ↓ call `goto` with a `GotoConfig` appropriate for your SDK version (here: `open` + `focus` both true).
- [ ] Gradient styling matches your app chrome (`AppTheme`).

---

## Quick Reference: This Example’s Flow

1. User taps a row in **FormsListViewController** → **SimpleFormContainerViewController** is pushed with a title.
2. **SimpleFormContainerViewController** embeds **FormContainerViewController** with `Validation.json`.
3. **FormContainerViewController** shows `Form` + **SampleFormFooterBar** via `formFooter`.
4. User taps **Submit** → validation bar appears (“X of Y Completed”).
5. User taps ↑ / ↓ → `goto` moves to previous/next invalid path.
6. Edits trigger **`onChange`** → counts and paths refresh while the validation bar is visible.
7. User taps ✕ → back to Submit state.
8. Switching pages may hide/show the footer via **`onFocus`** / **`onBlur`** when a `footerPageID` is configured.
