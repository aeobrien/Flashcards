import CoreData

class GroupService {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func createGroup(name: String) -> Group {
        let group = Group(context: context)
        group.groupID = UUID().uuidString
        group.groupName = name
        group.createdAt = Date()
        AppDelegate.shared.saveContext()
        return group
    }

    func fetchAllGroups() -> [Group] {
        let request: NSFetchRequest<Group> = Group.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching groups: \(error)")
            return []
        }
    }

    func addDeck(_ deck: Deck, to group: Group) {
        // Remove from previous group if any
        if let oldGroup = deck.group {
            oldGroup.removeFromDecks(deck)
        }
        group.addToDecks(deck)
        deck.group = group
        AppDelegate.shared.saveContext()
    }

    func removeDeck(_ deck: Deck, from group: Group) {
        group.removeFromDecks(deck)
        deck.group = nil
        AppDelegate.shared.saveContext()
    }

    func deleteGroup(_ group: Group) {
        // Unlink all decks first (don't delete them)
        if let decks = group.decks as? Set<Deck> {
            for deck in decks {
                deck.group = nil
            }
        }
        context.delete(group)
        AppDelegate.shared.saveContext()
    }

    func renameGroup(_ group: Group, to name: String) {
        group.groupName = name
        AppDelegate.shared.saveContext()
    }
}
