import UIKit

class ConceptListViewController: UIViewController {

    var deck: Deck?

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var concepts: [Concept] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Concepts"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissTapped))

        setupTableView()
        loadConcepts()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ConceptCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadConcepts() {
        guard let deck = deck else { return }
        let service = ConceptService(context: AppDelegate.getContext())
        concepts = service.fetchConcepts(for: deck).sorted {
            if $0.tier != $1.tier { return $0.tier < $1.tier }
            return ($0.name ?? "") < ($1.name ?? "")
        }
        tableView.reloadData()

        if concepts.isEmpty {
            showEmptyState()
        }
    }

    private func showEmptyState() {
        let label = UILabel()
        label.text = "No concepts found for this deck."
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .body)
        tableView.backgroundView = label
    }

    @objc private func dismissTapped() {
        dismiss(animated: true)
    }
}

extension ConceptListViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return concepts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConceptCell", for: indexPath)
        let concept = concepts[indexPath.row]

        var config = cell.defaultContentConfiguration()
        let tierLabel = "T\(concept.tier)"
        config.text = "\(concept.name ?? "Untitled")  [\(tierLabel)]"
        config.textProperties.font = .systemFont(ofSize: 16, weight: .semibold)
        config.secondaryText = concept.summary
        config.secondaryTextProperties.font = .preferredFont(forTextStyle: .subheadline)
        config.secondaryTextProperties.color = .secondaryLabel
        config.secondaryTextProperties.numberOfLines = 2
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let concept = concepts[indexPath.row]
        let detailVC = ConceptDetailViewController()
        detailVC.concept = concept
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
