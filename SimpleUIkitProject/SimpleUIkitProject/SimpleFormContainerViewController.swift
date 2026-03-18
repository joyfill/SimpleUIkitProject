//
//  SimpleFormContainerViewController.swift
//  SimpleUIkitProject
//

import UIKit
import SwiftUI
import Joyfill
import JoyfillModel

// MARK: - SimpleFormContainerViewController

class SimpleFormContainerViewController: UIViewController {

    var formTitle: String = "Form"

    private var formVC: FormContainerViewController!

    // Dedicated window so the footer floats above sheets and internal pushes
    private var footerWindow: FooterPassthroughWindow?
    private var footerView: GradientView!

    // State 1 — Submit button
    private var submitContainer: UIView!

    // State 2 — "X of Y Completed" + ^ v + ×
    private var validationContainer: UIView!
    private var completedLabel: UILabel!
    private var upButton: UIButton!
    private var downButton: UIButton!

    // Built from validate() result only
    private var fieldPaths: [String] = []
    private var currentFieldIndex: Int = -1

    private let footerContentHeight: CGFloat = 56

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = formTitle
        view.backgroundColor = .systemBackground
        additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: footerContentHeight, right: 0)
        createFooterView()
        setupFormNavigation()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        attachFooterWindow()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            detachFooterWindow()
        }
    }

    // MARK: - Footer Window Lifecycle

    private func attachFooterWindow() {
        guard footerWindow == nil,
              let scene = view.window?.windowScene else { return }

        let window = FooterPassthroughWindow(windowScene: scene)
        window.windowLevel = UIWindow.Level.statusBar
        window.backgroundColor = .clear
        window.isHidden = false

        let containerVC = UIViewController()
        containerVC.view.backgroundColor = .clear
        window.rootViewController = containerVC

        footerView.translatesAutoresizingMaskIntoConstraints = false
        containerVC.view.addSubview(footerView)

        NSLayoutConstraint.activate([
            footerView.leadingAnchor.constraint(equalTo: containerVC.view.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: containerVC.view.trailingAnchor),
            footerView.bottomAnchor.constraint(equalTo: containerVC.view.bottomAnchor),
            footerView.heightAnchor.constraint(equalToConstant: 80)
        ])

        footerWindow = window
    }

    private func detachFooterWindow() {
        footerWindow?.isHidden = true
        footerWindow = nil
    }

    // MARK: - Form Setup

    private func setupFormNavigation() {
        let document = loadDocument()
        formVC = FormContainerViewController(document: document)
        // Receive field change events
        formVC.documentEditor.events = self

        addChild(formVC)
        formVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(formVC.view)
        formVC.didMove(toParent: self)

        NSLayoutConstraint.activate([
            formVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            formVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            formVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            formVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Create Footer View

    private func createFooterView() {
        footerView = GradientView()
        setupSubmitContainer()
        setupValidationContainer()
        showSubmitState()
    }

    // MARK: - Submit Container (State 1)

    private func setupSubmitContainer() {
        submitContainer = UIView()
        submitContainer.translatesAutoresizingMaskIntoConstraints = false
        footerView.addSubview(submitContainer)

        let submitButton = UIButton(type: .system)
        submitButton.setTitle("Submit", for: .normal)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        submitContainer.addSubview(submitButton)

        NSLayoutConstraint.activate([
            submitContainer.topAnchor.constraint(equalTo: footerView.topAnchor),
            submitContainer.leadingAnchor.constraint(equalTo: footerView.leadingAnchor),
            submitContainer.trailingAnchor.constraint(equalTo: footerView.trailingAnchor),
            submitContainer.heightAnchor.constraint(equalToConstant: footerContentHeight),

            submitButton.centerXAnchor.constraint(equalTo: submitContainer.centerXAnchor),
            submitButton.centerYAnchor.constraint(equalTo: submitContainer.centerYAnchor)
        ])
    }

    // MARK: - Validation Container (State 2)

    private func setupValidationContainer() {
        validationContainer = UIView()
        validationContainer.translatesAutoresizingMaskIntoConstraints = false
        footerView.addSubview(validationContainer)

        completedLabel = UILabel()
        completedLabel.textColor = .white
        completedLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        completedLabel.translatesAutoresizingMaskIntoConstraints = false

        upButton = makeIconButton(systemName: "chevron.up")
        upButton.addTarget(self, action: #selector(upTapped), for: .touchUpInside)

        downButton = makeIconButton(systemName: "chevron.down")
        downButton.addTarget(self, action: #selector(downTapped), for: .touchUpInside)

        let separator = UIView()
        separator.backgroundColor = UIColor.white.withAlphaComponent(0.4)
        separator.translatesAutoresizingMaskIntoConstraints = false

        let closeButton = makeIconButton(systemName: "xmark")
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        [completedLabel, upButton, downButton, separator, closeButton].forEach {
            validationContainer.addSubview($0)
        }

        NSLayoutConstraint.activate([
            validationContainer.topAnchor.constraint(equalTo: footerView.topAnchor),
            validationContainer.leadingAnchor.constraint(equalTo: footerView.leadingAnchor),
            validationContainer.trailingAnchor.constraint(equalTo: footerView.trailingAnchor),
            validationContainer.heightAnchor.constraint(equalToConstant: footerContentHeight),

            completedLabel.leadingAnchor.constraint(equalTo: validationContainer.leadingAnchor, constant: 20),
            completedLabel.centerYAnchor.constraint(equalTo: validationContainer.centerYAnchor),

            closeButton.trailingAnchor.constraint(equalTo: validationContainer.trailingAnchor, constant: -20),
            closeButton.centerYAnchor.constraint(equalTo: validationContainer.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            separator.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -14),
            separator.centerYAnchor.constraint(equalTo: validationContainer.centerYAnchor),
            separator.widthAnchor.constraint(equalToConstant: 1),
            separator.heightAnchor.constraint(equalToConstant: 26),

            downButton.trailingAnchor.constraint(equalTo: separator.leadingAnchor, constant: -14),
            downButton.centerYAnchor.constraint(equalTo: validationContainer.centerYAnchor),
            downButton.widthAnchor.constraint(equalToConstant: 36),
            downButton.heightAnchor.constraint(equalToConstant: 36),

            upButton.trailingAnchor.constraint(equalTo: downButton.leadingAnchor, constant: -8),
            upButton.centerYAnchor.constraint(equalTo: validationContainer.centerYAnchor),
            upButton.widthAnchor.constraint(equalToConstant: 36),
            upButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    private func makeIconButton(systemName: String) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    // MARK: - Path Builder (shared between submitTapped and onChange)

    private func buildPaths(from validities: [FieldValidity]) -> [String] {
        // Only navigate to invalid fields / rows / cells
        validities
            .filter { $0.status == .invalid }
            .flatMap { validity -> [String] in
                guard let pageId = validity.pageId,
                      let posId = validity.fieldPositionId else { return [] }

                let base = "\(pageId)/\(posId)"

                // If no row-level detail, the field itself is the target
                guard let rowValidities = validity.rowValidities, !rowValidities.isEmpty else {
                    return [base]
                }

                return rowValidities
                    .filter { $0.status == .invalid }
                    .flatMap { row -> [String] in
                        guard let rowId = row.rowId else { return [base] }
                        let rowBase = "\(base)/\(rowId)"

                        let invalidCellPaths = row.cellValidities
                            .filter { $0.status == .invalid }
                            .compactMap { cell -> String? in
                                guard let columnId = cell.columnId else { return nil }
                                return "\(rowBase)/\(columnId)"
                            }

                        // If no cell-level detail, the row itself is the target
                        return invalidCellPaths.isEmpty ? [rowBase] : invalidCellPaths
                    }
            }
    }

    // MARK: - State Transitions

    private func showSubmitState() {
        submitContainer.isHidden = false
        validationContainer.isHidden = true
    }

    private func showValidationState(completed: Int, total: Int, hasInvalid: Bool) {
        completedLabel.text = "\(completed) of \(total) Completed"
        upButton.isEnabled = hasInvalid
        downButton.isEnabled = hasInvalid
        upButton.alpha = hasInvalid ? 1.0 : 0.4
        downButton.alpha = hasInvalid ? 1.0 : 0.4
        submitContainer.isHidden = true
        validationContainer.isHidden = false
    }

    // MARK: - Actions

    @objc private func submitTapped() {
        let validation = formVC.documentEditor.validate()
        let validities = validation.fieldValidities
        let total = validities.count
        let completed = validities.filter { $0.status == .valid }.count

        fieldPaths = buildPaths(from: validities)
        currentFieldIndex = -1
        showValidationState(completed: completed, total: total, hasInvalid: validation.status == .invalid)
    }

    @objc private func upTapped() {
        guard !fieldPaths.isEmpty else { return }
        currentFieldIndex = currentFieldIndex <= 0 ? fieldPaths.count - 1 : currentFieldIndex - 1
        _ = formVC.documentEditor.goto(fieldPaths[currentFieldIndex], gotoConfig: GotoConfig(open: true, focus: true))
    }

    @objc private func downTapped() {
        guard !fieldPaths.isEmpty else { return }
        currentFieldIndex = (currentFieldIndex + 1) % fieldPaths.count
        _ = formVC.documentEditor.goto(fieldPaths[currentFieldIndex], gotoConfig: GotoConfig(focus: true))
    }

    @objc private func closeTapped() {
        fieldPaths = []
        currentFieldIndex = -1
        showSubmitState()
    }

    // MARK: - Load Document

    private func loadDocument() -> JoyDoc {
        let path = Bundle.main.path(forResource: "Validation", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let dict = try! JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as! [String: Any]
        return JoyDoc(dictionary: dict)
    }
}

// MARK: - FormChangeEvent

extension SimpleFormContainerViewController: FormChangeEvent {

    func onChange(changes: [Change], document: JoyDoc) {
        DispatchQueue.main.async {
            // Only update footer if we're already in validation state
            guard !self.validationContainer.isHidden else { return }

            let validation = self.formVC.documentEditor.validate()
            let validities = validation.fieldValidities
            let total = validities.count
            let completed = validities.filter { $0.status == .valid }.count

            // Rebuild paths from fresh validation result
            self.fieldPaths = self.buildPaths(from: validities)

            // Clamp index if paths shrank
            if self.currentFieldIndex >= self.fieldPaths.count {
                self.currentFieldIndex = self.fieldPaths.isEmpty ? -1 : self.fieldPaths.count - 1
            }

            self.showValidationState(
                completed: completed,
                total: total,
                hasInvalid: validation.status == .invalid
            )
        }
    }

    func onFocus(event: Event) {}
    func onBlur(event: Event) {}
    func onUpload(event: Joyfill.UploadEvent) {}
    func onCapture(event: Joyfill.CaptureEvent) {}
    func onError(error: Joyfill.JoyfillError) {}
}


