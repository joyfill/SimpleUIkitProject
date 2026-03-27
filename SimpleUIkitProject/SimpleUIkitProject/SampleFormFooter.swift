//
//  SampleFormFooter.swift
//  SimpleUIkitProject
//

import Combine
import SwiftUI
import Joyfill
import JoyfillModel
import UIKit

// MARK: - Footer coordinator (validate / navigate + FormChangeEvent)

final class SampleFormFooterController: ObservableObject, FormChangeEvent {

    weak var documentEditor: DocumentEditor?

    @Published private(set) var showValidationBar = false
    @Published private(set) var completedText = ""
    @Published private(set) var navigationEnabled = false

    private var fieldPaths: [String] = []
    private var currentFieldIndex: Int = -1

    func submitTapped() {
        guard let editor = documentEditor else { return }
        let validation = editor.validate()
        let validities = validation.fieldValidities
        let total = validities.count
        let completed = validities.filter { $0.status == .valid }.count

        fieldPaths = Self.buildPaths(from: validities)
        currentFieldIndex = -1
        completedText = "\(completed) of \(total) Completed"
        navigationEnabled = validation.status == .invalid
        showValidationBar = true
    }

    func upTapped() {
        guard let editor = documentEditor, !fieldPaths.isEmpty else { return }
        currentFieldIndex = currentFieldIndex <= 0 ? fieldPaths.count - 1 : currentFieldIndex - 1
        _ = editor.goto(fieldPaths[currentFieldIndex], gotoConfig: GotoConfig(open: true, focus: true))
    }

    func downTapped() {
        guard let editor = documentEditor, !fieldPaths.isEmpty else { return }
        currentFieldIndex = (currentFieldIndex + 1) % fieldPaths.count
        _ = editor.goto(fieldPaths[currentFieldIndex], gotoConfig: GotoConfig(open: true, focus: true))
    }

    func closeTapped() {
        fieldPaths = []
        currentFieldIndex = -1
        showValidationBar = false
    }

    // MARK: - FormChangeEvent

    func onChange(changes: [Change], document: JoyDoc) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.showValidationBar, let editor = self.documentEditor else { return }

            let validation = editor.validate()
            let validities = validation.fieldValidities
            let total = validities.count
            let completed = validities.filter { $0.status == .valid }.count

            self.fieldPaths = Self.buildPaths(from: validities)
            if self.currentFieldIndex >= self.fieldPaths.count {
                self.currentFieldIndex = self.fieldPaths.isEmpty ? -1 : self.fieldPaths.count - 1
            }
            self.completedText = "\(completed) of \(total) Completed"
            self.navigationEnabled = validation.status == .invalid
        }
    }

    func onFocus(event: Event) {}
    func onBlur(event: Event) {}
    func onUpload(event: Joyfill.UploadEvent) {}
    func onCapture(event: Joyfill.CaptureEvent) {}
    func onError(error: Joyfill.JoyfillError) {}

    // MARK: - Paths

    private static func buildPaths(from validities: [FieldValidity]) -> [String] {
        validities
            .filter { $0.status == .invalid }
            .flatMap { validity -> [String] in
                guard let pageId = validity.pageId,
                      let posId = validity.fieldPositionId else { return [] }

                let base = "\(pageId)/\(posId)"

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

                        return invalidCellPaths.isEmpty ? [rowBase] : invalidCellPaths
                    }
            }
    }
}

// MARK: - SwiftUI bar

struct SampleFormFooterBar: View {
    @ObservedObject var controller: SampleFormFooterController

    var body: some View {
        VStack(spacing: 0) {
            if controller.showValidationBar {
                validationContent
            } else {
                submitContent
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 56)
        .background(
            LinearGradient(
                colors: [
                    Color(uiColor: AppTheme.gradientStart),
                    Color(uiColor: AppTheme.gradientEnd)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    private var submitContent: some View {
        Button(action: { controller.submitTapped() }) {
            Text("Submit")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)
        }
        .buttonStyle(.plain)
    }

    private var validationContent: some View {
        HStack(spacing: 12) {
            Text(controller.completedText)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                navButton(systemName: "chevron.up", action: { controller.upTapped() }, dimsWhenDisabled: true)
                navButton(systemName: "chevron.down", action: { controller.downTapped() }, dimsWhenDisabled: true)
            }

            Rectangle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 1, height: 26)

            navButton(systemName: "xmark", action: { controller.closeTapped() }, dimsWhenDisabled: false)
        }
        .padding(.horizontal, 20)
        .frame(minHeight: 56)
    }

    private func navButton(systemName: String, action: @escaping () -> Void, dimsWhenDisabled: Bool) -> some View {
        let enabled = !dimsWhenDisabled || controller.navigationEnabled
        return Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }
}
