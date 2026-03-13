//
//  FormsListViewController.swift
//  SimpleUIkitProject
//
//  List of available forms — tap a row to open SimpleFormContainerViewController.
//

import UIKit

struct FormItem {
    let title: String
    let subtitle: String
}

class FormsListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let forms: [FormItem] = [
        FormItem(title: "Validation Form", subtitle: "Fields, collections, charts & tables"),
        FormItem(title: "Inspection Report", subtitle: "Standard inspection checklist"),
        FormItem(title: "Work Order", subtitle: "Job details and completion notes"),
        FormItem(title: "Safety Assessment", subtitle: "On-site safety evaluation"),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Forms"
        view.backgroundColor = .systemGroupedBackground
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FormCell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

// MARK: - UITableViewDataSource

extension FormsListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        forms.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FormCell", for: indexPath)
        let form = forms[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = form.title
        config.secondaryText = form.subtitle
        config.image = UIImage(systemName: "doc.text")
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

// MARK: - UITableViewDelegate

extension FormsListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let formVC = SimpleFormContainerViewController()
        navigationController?.pushViewController(formVC, animated: true)
    }
}
