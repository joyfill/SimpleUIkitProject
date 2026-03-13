//
//  NavigationControlsView.swift
//  SimpleUIkitProject
//
//  Header-only navigation controls — single horizontal row; text truncates.
//

import SwiftUI
import Joyfill
import JoyfillModel

struct NavigationControlsView: View {
    @ObservedObject var documentEditor: DocumentEditor
    var onBack: (() -> Void)? = nil

    @State private var selectedPageId: String = ""
    @State private var selectedFieldPositionId: String = ""
    @State private var selectedRowId: String = ""
    @State private var openModal: Bool = true
    @State private var focusField: Bool = true
    @State private var selectedColumnId: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var allPages: [Page] {
        documentEditor.pagesForCurrentView
    }

    var fieldPositionsForSelectedPage: [FieldPosition] {
        guard let page = allPages.first(where: { $0.id == selectedPageId }) else { return [] }
        return page.fieldPositions ?? []
    }

    var rowsForSelectedField: [ValueElement] {
        guard let fieldPosition = fieldPositionsForSelectedPage.first(where: { $0.id == selectedFieldPositionId }),
              let fieldId = fieldPosition.field,
              let field = documentEditor.field(fieldID: fieldId),
              (field.fieldType == .table || field.fieldType == .collection),
              let valueElements = field.value?.valueElements else { return [] }
        return valueElements
    }

    var selectedFieldIsTableOrCollection: Bool {
        guard let fieldPosition = fieldPositionsForSelectedPage.first(where: { $0.id == selectedFieldPositionId }),
              let fieldId = fieldPosition.field,
              let field = documentEditor.field(fieldID: fieldId) else { return false }
        return field.fieldType == .table || field.fieldType == .collection
    }

    var columnsForSelectedField: [FieldTableColumn] {
        guard let fieldPosition = fieldPositionsForSelectedPage.first(where: { $0.id == selectedFieldPositionId }),
              let fieldId = fieldPosition.field,
              let field = documentEditor.field(fieldID: fieldId) else { return [] }
        if field.fieldType == .collection {
            guard let schema = field.schema,
                  let rootSchema = schema.first(where: { $0.value.root == true })?.value,
                  let columns = rootSchema.tableColumns else { return [] }
            return columns
        }
        return field.tableColumns ?? []
    }

    private let rowHeight: CGFloat = 44
    private let pickerMinWidth: CGFloat = 72

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    if let onBack = onBack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                                .foregroundColor(.accentColor)
                        }
                        .frame(width: 30, height: rowHeight)
                    }
                    pagePicker
                    fieldPicker
                    if selectedFieldIsTableOrCollection { rowPicker }
                    if selectedFieldIsTableOrCollection && !selectedRowId.isEmpty { columnPicker }
                    navigateButton
                }
                .padding(.horizontal, 12)
                .frame(height: rowHeight)
            }
            .frame(height: rowHeight)
            .background(Color(UIColor.systemGroupedBackground))

            Divider()
        }
        .alert("Navigation Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            if let firstPage = allPages.first, let firstPageId = firstPage.id {
                selectedPageId = firstPageId
            }
        }
    }

    private var pagePicker: some View {
        Picker("Page", selection: $selectedPageId) {
            Text("Select page...").tag("")
            ForEach(allPages, id: \.id) { page in
                if let id = page.id {
                    Text(page.name ?? "Page \(id.prefix(8))")
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .tag(id)
                }
            }
        }
        .pickerStyle(.menu)
        .frame(minWidth: pickerMinWidth, maxWidth: 120, minHeight: rowHeight, maxHeight: rowHeight)
        .onChange(of: selectedPageId) { _ in
            selectedFieldPositionId = ""
            selectedRowId = ""
        }
    }

    private var fieldPicker: some View {
        Picker("Field", selection: $selectedFieldPositionId) {
            Text("Select field...").tag("")
            ForEach(fieldPositionsForSelectedPage, id: \.id) { fieldPosition in
                if let id = fieldPosition.id {
                    Group {
                        if let fieldId = fieldPosition.field,
                           let field = documentEditor.field(fieldID: fieldId) {
                            Text(field.title ?? "Field \(id.prefix(8))")
                        } else {
                            Text("Field \(id.prefix(8))")
                        }
                    }
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .tag(id)
                }
            }
        }
        .pickerStyle(.menu)
        .frame(minWidth: pickerMinWidth, maxWidth: 120, minHeight: rowHeight, maxHeight: rowHeight)
        .disabled(selectedPageId.isEmpty)
        .onChange(of: selectedFieldPositionId) { _ in selectedRowId = "" }
    }

    private var rowPicker: some View {
        Picker("Row", selection: $selectedRowId) {
            Text("Select row...").tag("")
            ForEach(Array(rowsForSelectedField.enumerated()), id: \.offset) { index, row in
                if let id = row.id {
                    let label = row.deleted == true
                        ? "Row \(index + 1) [DELETED]"
                        : "Row \(index + 1) - \(id.prefix(8))"
                    Text(label)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .tag(id)
                }
            }
        }
        .pickerStyle(.menu)
        .frame(minWidth: pickerMinWidth, maxWidth: 120, minHeight: rowHeight, maxHeight: rowHeight)
        .disabled(selectedFieldPositionId.isEmpty)
        .onChange(of: selectedRowId) { _ in selectedColumnId = "" }
    }

    private var columnPicker: some View {
        Picker("Column", selection: $selectedColumnId) {
            Text("No column").tag("")
            ForEach(columnsForSelectedField, id: \.id) { col in
                if let id = col.id {
                    Text(col.title.isEmpty ? "Col \(id.prefix(8))" : col.title)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .tag(id)
                }
            }
        }
        .pickerStyle(.menu)
        .frame(minWidth: pickerMinWidth, maxWidth: 120, minHeight: rowHeight, maxHeight: rowHeight)
    }

    private var navigateButton: some View {
        Button(action: performDropdownGoto) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.title2)
        }
        .frame(width: rowHeight, height: rowHeight)
        .foregroundColor(.white)
        .background(selectedPageId.isEmpty ? Color.gray : Color.blue)
        .cornerRadius(8)
        .disabled(selectedPageId.isEmpty)
    }

    private func performDropdownGoto() {
        guard !selectedPageId.isEmpty else { return }
        let status: NavigationStatus
        if !selectedRowId.isEmpty {
            var path = "\(selectedPageId)/\(selectedFieldPositionId)/\(selectedRowId)"
            if !selectedColumnId.isEmpty { path += "/\(selectedColumnId)" }
            status = documentEditor.goto(path, gotoConfig: GotoConfig(open: openModal, focus: focusField))
        } else if !selectedFieldPositionId.isEmpty {
            status = documentEditor.goto("\(selectedPageId)/\(selectedFieldPositionId)", gotoConfig: GotoConfig(focus: focusField))
        } else {
            status = documentEditor.goto(selectedPageId, gotoConfig: GotoConfig(focus: focusField))
        }
        if status == .failure {
            alertMessage = "Navigation failed"
            showAlert = true
        }
    }
}

