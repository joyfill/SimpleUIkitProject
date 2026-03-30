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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = formTitle
        view.backgroundColor = .systemBackground
        setupFormNavigation()
    }

    // MARK: - Form Setup

    private func setupFormNavigation() {
        let document = loadDocument()
        formVC = FormContainerViewController(document: document)

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

    // MARK: - Load Document

    private func loadDocument() -> JoyDoc {
        let path = Bundle.main.path(forResource: "Validation", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let dict = try! JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as! [String: Any]
        return JoyDoc(dictionary: dict)
    }
}
