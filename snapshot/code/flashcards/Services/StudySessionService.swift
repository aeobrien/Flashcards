import CoreData

class StudySessionService {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func createSession(for deck: Deck) -> StudySession {
        let session = StudySession(context: context)
        session.sessionID = UUID().uuidString
        session.startedAt = Date()
        session.deck = deck
        deck.addToStudySessions(session)
        AppDelegate.shared.saveContext()
        return session
    }

    func createGroupSession(for group: Group) -> StudySession {
        let session = StudySession(context: context)
        session.sessionID = UUID().uuidString
        session.startedAt = Date()
        session.group = group
        group.addToStudySessions(session)
        AppDelegate.shared.saveContext()
        return session
    }

    func completeSession(_ session: StudySession) {
        session.completedAt = Date()
        AppDelegate.shared.saveContext()
    }

    func addResponse(to session: StudySession,
                     flashcard: Flashcard,
                     userAnswer: String,
                     grade: Int16,
                     feedback: String) -> SessionResponse {
        let response = SessionResponse(context: context)
        response.responseID = UUID().uuidString
        response.userAnswer = userAnswer
        response.grade = grade
        response.feedback = feedback
        response.answeredAt = Date()
        response.flashcard = flashcard
        response.session = session
        session.addToResponses(response)
        flashcard.addToSessionResponses(response)
        AppDelegate.shared.saveContext()
        return response
    }

    func fetchLatestSession(for deck: Deck) -> StudySession? {
        let request: NSFetchRequest<StudySession> = StudySession.fetchRequest()
        request.predicate = NSPredicate(format: "deck == %@", deck)
        request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching latest session: \(error)")
            return nil
        }
    }
}
