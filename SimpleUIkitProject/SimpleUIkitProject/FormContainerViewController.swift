//
//  FormContainerViewController.swift
//  SimpleUIkitProject
//

import SwiftUI
import UIKit
import Joyfill
import JoyfillModel

class FormContainerViewController: UIViewController {
    var document: JoyDoc!
    var currentPage: String? = nil
    var documentEditor: DocumentEditor!
    private let footerController = SampleFormFooterController()

    init(document: JoyDoc? = nil, currentPage: String? = nil) {
        self.document = document
        self.currentPage = currentPage
        super.init(nibName: nil, bundle: nil)
        self.document = document ?? sampleJSONDocument()
        let footerPageID = Self.defaultFooterPageID(in: self.document!)
        self.documentEditor = DocumentEditor(document: self.document!, mode: .fill, pageID: currentPage, isPageDuplicateEnabled: true, isPageDeleteEnabled: true, validateSchema: false, singleClickRowEdit: true)
        self.documentEditor.events = footerController
        footerController.documentEditor = documentEditor
        footerController.configureFooterVisibility(visibleOnPageID: footerPageID, initialPageID: currentPage)
    }

    func sampleJSONDocument() -> JoyDoc {
        let path = Bundle.main.path(forResource: "Validation", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let dict = try! JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as! [String: Any]
        return JoyDoc(dictionary: dict)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let hostingController = UIHostingController(rootView: joyFillView)
        addChild(hostingController)
        view.addSubview(hostingController.view)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        hostingController.didMove(toParent: self)
    }

    @ViewBuilder
    var joyFillView: some View {
        Form(documentEditor: self.documentEditor)
            .formFooter {
                SampleFormFooterBar(controller: self.footerController)
            }
    }

    private static func defaultFooterPageID(in document: JoyDoc) -> String? {
        document.pagesForCurrentView.first?.id ?? document.pageOrderForCurrentView.first
    }
}
