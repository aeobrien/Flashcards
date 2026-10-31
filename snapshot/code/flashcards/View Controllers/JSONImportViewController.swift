import UIKit
import UniformTypeIdentifiers

class JSONImportViewController: UIViewController {

    // MARK: - Properties

    private let importService: JSONImportService
    private let deckService: DeckService

    // Set externally to skip deck-selection for cards-only imports
    var targetDeck: Deck?

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Select a JSON file to import"
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Init

    init() {
        let context = AppDelegate.getContext()
        self.importService = JSONImportService(context: context)
        self.deckService = DeckService(context: context)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Import JSON"
        view.backgroundColor = .systemGroupedBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))

        view.addSubview(statusLabel)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -20),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentFilePicker()
    }

    // MARK: - File Picker

    private func presentFilePicker() {
        let jsonType = UTType.json
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [jsonType])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    // MARK: - Import Logic

    private func handleFile(at url: URL) {
        activityIndicator.startAnimating()
        statusLabel.text = "Reading file..."

        guard url.startAccessingSecurityScopedResource() else {
            showError("Unable to access the selected file.")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            showError("Failed to read file: \(error.localizedDescription)")
            return
        }

        let importType: ImportType
        do {
            importType = try importService.detectImportType(from: data)
        } catch {
            showError(error.localizedDescription)
            return
        }

        switch importType {
        case .cards:
            handleCardsImport(data: data)
        case .deck:
            handleDeckImport(data: data)
        case .group:
            handleGroupImport(data: data)
        }
    }

    private func handleCardsImport(data: Data) {
        if let deck = targetDeck {
            performCardsImport(data: data, into: deck)
            return
        }

        activityIndicator.stopAnimating()

        let alert = UIAlertController(title: "Import Cards", message: "Where would you like to add these cards?", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Create New Deck", style: .default) { [weak self] _ in
            self?.promptForNewDeck { deck in
                self?.performCardsImport(data: data, into: deck)
            }
        })

        let allDecks = deckService.fetchAllDecks().sorted { ($0.deckName ?? "") < ($1.deckName ?? "") }
        if !allDecks.isEmpty {
            alert.addAction(UIAlertAction(title: "Add to Existing Deck", style: .default) { [weak self] _ in
                self?.showDeckPicker(decks: allDecks) { deck in
                    self?.performCardsImport(data: data, into: deck)
                }
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        })

        present(alert, animated: true)
    }

    private func performCardsImport(data: Data, into deck: Deck) {
        activityIndicator.startAnimating()
        statusLabel.text = "Importing cards..."

        do {
            let result = try importService.importCards(from: data, into: deck)
            showSuccess(result.message)
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func handleDeckImport(data: Data) {
        statusLabel.text = "Importing deck..."

        do {
            let result = try importService.importDeck(from: data)
            showSuccess(result.message)
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func handleGroupImport(data: Data) {
        statusLabel.text = "Importing group..."

        do {
            let result = try importService.importGroup(from: data)
            showSuccess(result.message)
        } catch {
            showError(error.localizedDescription)
        }
    }

    // MARK: - Deck Selection Helpers

    private func promptForNewDeck(completion: @escaping (Deck) -> Void) {
        let alert = UIAlertController(title: "New Deck", message: "Enter a name for the new deck.", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Deck name"
            tf.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        alert.addAction(UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty,
                  let self = self else { return }
            let deck = self.deckService.createDeck(deckName: name, description: "")
            completion(deck)
        })
        present(alert, animated: true)
    }

    private func showDeckPicker(decks: [Deck], completion: @escaping (Deck) -> Void) {
        let alert = UIAlertController(title: "Select Deck", message: nil, preferredStyle: .actionSheet)
        for deck in decks {
            let cardCount = deck.flashcards?.count ?? 0
            alert.addAction(UIAlertAction(title: "\(deck.deckName ?? "Untitled") (\(cardCount) cards)", style: .default) { _ in
                completion(deck)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    // MARK: - Feedback

    private func showSuccess(_ message: String) {
        activityIndicator.stopAnimating()
        statusLabel.text = message
        statusLabel.textColor = .systemGreen

        let alert = UIAlertController(title: "Import Successful", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    private func showError(_ message: String) {
        activityIndicator.stopAnimating()
        statusLabel.text = message
        statusLabel.textColor = .systemRed

        let alert = UIAlertController(title: "Import Failed", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate

extension JSONImportViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            dismiss(animated: true)
            return
        }
        handleFile(at: url)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dismiss(animated: true)
    }
}
