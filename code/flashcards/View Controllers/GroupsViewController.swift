import UIKit

class GroupsViewController: UIViewController {

    // MARK: - Properties

    private let groupService = GroupService(context: AppDelegate.getContext())
    private var groups: [Group] = []

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyLabel = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Groups"
        view.backgroundColor = .systemGroupedBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addGroupTapped))

        NotificationCenter.default.addObserver(self, selector: #selector(reloadGroups), name: .didUpdateGroups, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadGroups), name: .didUpdateDecks, object: nil)

        setupUI()
        reloadGroups()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupUI() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "GroupCell")
        view.addSubview(tableView)

        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = "No groups yet.\nTap + to create a group and combine decks for interleaved study."
        emptyLabel.font = .preferredFont(forTextStyle: .body)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }

    // MARK: - Data

    @objc private func reloadGroups() {
        groups = groupService.fetchAllGroups()
        tableView.reloadData()
        emptyLabel.isHidden = !groups.isEmpty
        tableView.isHidden = groups.isEmpty
    }

    // MARK: - Actions

    @objc private func addGroupTapped() {
        let alert = UIAlertController(title: "New Group", message: "Enter a name for this study group.", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "e.g., Final Exam Review"
            tf.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { return }
            _ = self?.groupService.createGroup(name: name)
            NotificationCenter.default.post(name: .didUpdateGroups, object: nil)
        })
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate & DataSource

extension GroupsViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupCell", for: indexPath)
        let group = groups[indexPath.row]
        let deckCount = group.decks?.count ?? 0

        var config = cell.defaultContentConfiguration()
        config.text = group.groupName ?? "Untitled Group"
        config.secondaryText = "\(deckCount) deck\(deckCount == 1 ? "" : "s")"
        config.image = UIImage(systemName: "rectangle.stack")
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let group = groups[indexPath.row]
        let detailVC = GroupDetailViewController()
        detailVC.group = group
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let group = groups[indexPath.row]

        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            let alert = UIAlertController(title: "Delete Group?", message: "This will remove the group but keep all its decks.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completion(false) })
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                self?.groupService.deleteGroup(group)
                NotificationCenter.default.post(name: .didUpdateGroups, object: nil)
                completion(true)
            })
            self?.present(alert, animated: true)
        }

        let rename = UIContextualAction(style: .normal, title: "Rename") { [weak self] _, _, completion in
            let alert = UIAlertController(title: "Rename Group", message: nil, preferredStyle: .alert)
            alert.addTextField { tf in tf.text = group.groupName }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completion(false) })
            alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
                if let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
                    self?.groupService.renameGroup(group, to: name)
                    NotificationCenter.default.post(name: .didUpdateGroups, object: nil)
                }
                completion(true)
            })
            self?.present(alert, animated: true)
        }
        rename.backgroundColor = .systemBlue

        return UISwipeActionsConfiguration(actions: [delete, rename])
    }
}
