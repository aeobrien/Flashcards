import UIKit
import Combine

class MyDecksViewController: UIViewController {

    @IBOutlet var cardView: CustomView!
    @IBOutlet var blurView: UIVisualEffectView!
    @IBOutlet var recentCollectionView: UICollectionView!
    @IBOutlet var decksTabelView: UITableView!
    @IBOutlet var tableViewHeight: NSLayoutConstraint!
    @IBOutlet var scrollView: UIScrollView!

    @IBOutlet var lastVisitedDeckProgressBar: UIProgressView!
    @IBOutlet var lastVisitedDeckName: UILabel!
    @IBOutlet var lastVisitedDeckStatus: UILabel!

    private var tokens: Set<AnyCancellable> = []

    var deckService: DeckService!

    var allDecks: [Deck] = []
    var recentDecks: [Deck] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLongPressGesture()

        NotificationCenter.default.addObserver(self, selector: #selector(fetchDecks), name: .didUpdateDecks, object: nil)

        deckService = DeckService(context: AppDelegate.getContext())
        fetchDecks()

        recentCollectionView.delegate = self
        recentCollectionView.dataSource = self
        recentCollectionView.layer.masksToBounds = false

        decksTabelView.delegate = self
        decksTabelView.dataSource = self
        decksTabelView.layer.masksToBounds = false
        decksTabelView.separatorStyle = .none

        decksTabelView.publisher(for: \.contentSize)
            .sink { newContentSize in
                self.tableViewHeight.constant = newContentSize.height
            }
            .store(in: &tokens)

        scrollView.delegate = self

        // Add settings button to navigation bar
        let settingsButton = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(settingsTapped))
        navigationItem.leftBarButtonItem = settingsButton
    }

    @objc func fetchDecks() {
        allDecks = deckService.fetchAllDecks()
        recentDecks = allDecks.sorted { ($0.lastViewed ?? Date.distantPast) > ($1.lastViewed ?? Date.distantPast) }.prefix(3).map { $0 }
        allDecks.sort { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
        decksTabelView.reloadData()
        recentCollectionView.reloadData()
        updateLastVisitedDeckUI()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let detailsVC = segue.destination as? FlashcardsViewController, let deck = sender as? Deck {
            detailsVC.deck = deck
        }
    }

    // Intercept the add-deck segue to show action sheet
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // The add deck segue has empty identifier — intercept bar button segues to AddNewDeck
        if identifier == "" {
            showAddDeckOptions()
            return false
        }
        return true
    }

    private func showAddDeckOptions() {
        let alert = UIAlertController(title: "New Deck", message: "How would you like to create your deck?", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Create Manually", style: .default) { [weak self] _ in
            self?.presentManualDeckCreation()
        })

        alert.addAction(UIAlertAction(title: "Generate with AI", style: .default) { [weak self] _ in
            self?.presentAIGeneration()
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    private func presentManualDeckCreation() {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "AddNewDeckViewController") as? AddNewDeckViewController else { return }
        vc.modalPresentationStyle = .formSheet
        present(vc, animated: true)
    }

    private func presentAIGeneration() {
        let aiInputVC = AIInputViewController()
        let navController = UINavigationController(rootViewController: aiInputVC)
        navController.modalPresentationStyle = .formSheet
        present(navController, animated: true)
    }

    @objc private func settingsTapped() {
        let settingsVC = SettingsViewController()
        let navController = UINavigationController(rootViewController: settingsVC)
        navController.modalPresentationStyle = .formSheet
        present(navController, animated: true)
    }

    func updateLastVisitedDeckUI() {
        guard let mostRecentDeck = allDecks.max(by: { ($0.lastViewed ?? Date.distantPast) < ($1.lastViewed ?? Date.distantPast) }) else {
            lastVisitedDeckName.text = "No Decks Visited Yet"
            lastVisitedDeckStatus.text = "No Data"
            lastVisitedDeckProgressBar.progress = 0.0
            return
        }

        lastVisitedDeckName.text = mostRecentDeck.deckName
        lastVisitedDeckStatus.text = "\(mostRecentDeck.flashcards?.count ?? 0) TOTAL CARDS | \(mostRecentDeck.completedCount) COMPLETED"

        let completionRate = (mostRecentDeck.flashcards?.count ?? 0) > 0 ? Float(mostRecentDeck.completedCount) / Float(mostRecentDeck.flashcards?.count ?? 1) : 0.0
        lastVisitedDeckProgressBar.setProgress(completionRate, animated: true)
    }

    func updateAndRefreshUI(for deck: Deck) {
        deckService.updateLastViewed(for: deck)
        fetchDecks()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
