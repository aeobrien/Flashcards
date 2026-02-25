# Flashcards App Enhancement Plan
## Grounded in Learning Science Principles

### Context
The app implements spaced repetition (Leitner boxes), tiered difficulty with progressive unlocking, AI card generation, AI grading, and voice-based answer input. However, several key learning science principles from MakeItStick.txt remain unimplemented — most notably interleaving, calibration, and metacognition. This plan adds those missing principles plus quality-of-life improvements.

---

## Implementation Items (Priority Order)

### 1. Groups — Cross-Deck Interleaving
**Principle:** Interleaving (mixing topics during study) produces stronger long-term retention than blocked practice.

**What:** A new `Group` Core Data entity that umbrellas multiple decks. Users can study a group, which shuffles due cards across all member decks.

**Implementation:**
- **Core Data Model 5:** New `Group` entity with `groupID`, `groupName`, `createdAt` attributes. One-to-many relationship to `Deck`. Add inverse `group` (optional, many-to-one) on Deck. A deck can belong to zero or one group.
- **Replace Favourites tab** with a new `GroupsViewController`. Shows list of groups. Tap group → `GroupDetailViewController` showing member decks + "Practice Group" button.
- **GroupService:** CRUD for groups, add/remove decks from groups.
- **SchedulingService changes:** New `fetchDueFlashcards(for group: Group)` that queries across all decks in the group, filters to unlocked+due cards, returns shuffled.
- **StudySessionViewController changes:** Accept either a `Deck` or a `Group` as context. When group-based, the session mixes cards from all member decks. Session results show which deck each card came from.
- **StudySession entity:** Add optional `group` relationship (many-to-one) so sessions can be linked to either a deck or a group.

**Files to modify:**
- `Model.xcdatamodeld/` → new Model 5
- New entity files: `Group+CoreDataClass.swift`, `Group+CoreDataProperties.swift`
- `Deck+CoreDataProperties.swift` (add group relationship)
- `StudySession+CoreDataProperties.swift` (add group relationship)
- New: `GroupService.swift`
- New: `GroupsViewController.swift`, `GroupDetailViewController.swift`
- `SchedulingService.swift` (add group-level fetching)
- `StudySessionViewController.swift` (accept group context)
- `SessionResultsViewController.swift` (show deck origin per card)
- `Main.storyboard` (replace Favourites tab)
- `NotificationExtensions.swift` (add `.didUpdateGroups`)
- `AppDelegate.swift` (lightweight migration to Model 5)

---

### 2. Store Source Materials on Deck
**Principle:** Having all study material in one place supports elaboration and re-study after failed retrieval.

**What:** Persist the user's original notes text on the Deck entity so they can review the source material that generated their cards.

**Implementation:**
- **Core Data Model 5:** Add `sourceNotes: String (optional)` attribute to Deck entity.
- **CardReviewViewController.saveTapped():** Save `originalNotes` to `deck.sourceNotes` (currently discarded after generation).
- **FlashcardsViewController:** Add a "View Notes" button/section that displays the stored source notes in a scrollable read-only view.
- New: `SourceNotesViewController.swift` — simple VC to display the notes.

**Files to modify:**
- `Model.xcdatamodeld/` (Model 5 — same migration as item 1)
- `Deck+CoreDataProperties.swift`
- `CardReviewViewController.swift` (persist notes on save)
- `FlashcardsViewController.swift` (add notes access)
- New: `SourceNotesViewController.swift`

---

### 3. Text Input Alongside Voice
**Principle:** Accessibility and reliability — users need a fallback when voice doesn't work.

**What:** Add a text input mode to StudySessionViewController so users can type answers instead of (or in addition to) speaking them.

**Implementation:**
- Add a segmented control or toggle button (mic icon / keyboard icon) above the input area.
- **Voice mode (current):** Microphone button + read-only transcription preview.
- **Text mode (new):** Editable UITextView replaces mic button area. Submit button activates when text is entered.
- Both modes write to the same `userAnswers` array. User can switch mid-session.
- Transcription preview becomes editable in voice mode too (so users can correct transcription errors before submitting).

**Files to modify:**
- `StudySessionViewController.swift` (add input mode toggle, editable text view, show/hide mic)

---

### 4. Shuffle Within Sessions (Fix Blocked Practice)
**Principle:** Even within a single deck, interleaving card order is better than blocked (all box-1, then all box-2).

**What:** Shuffle due cards randomly instead of sorting by Leitner box.

**Implementation:**
- `SchedulingService.fetchDueFlashcards()` currently sorts by `leitnerBox` ascending then `lastReviewedAt`. Change to: fetch with the same predicates (unlocked + due only) but return `.shuffled()` instead of sorted.
- The existing shuffle in `FlashcardsViewController.viewAllFlashcards()` (when picking a subset) already shuffles — but the underlying fetch order bleeds through when taking all cards. Fix at the source.

**Files to modify:**
- `SchedulingService.swift` (remove sort descriptors, shuffle result)

---

### 5. Calibration Dashboard
**Principle:** Combat "illusions of knowing" — users need objective mastery visualization, not gut feeling.

**What:** A dashboard showing per-deck and per-concept mastery status, weak areas, and study history.

**Implementation:**
- New `DashboardViewController` accessible from FlashcardsViewController (per-deck) and GroupDetailViewController (per-group).
- **Per-deck view:** Card state distribution (locked/available/learning/mastered), tier breakdown, average grades over time, cards overdue count, weakest concepts (lowest average grade).
- **Per-group view:** Same metrics aggregated across all decks in the group.
- All data already exists in Core Data — this is purely a UI/query task.
- Use simple UIStackView layouts with progress bars and labels. No charting library needed.

**Files to modify:**
- New: `DashboardViewController.swift`
- `FlashcardsViewController.swift` (add dashboard button)
- `GroupDetailViewController.swift` (add dashboard button)

---

### 6. Minimum Spacing Before Promotion
**Principle:** A single correct retrieval doesn't mean durable learning — require success across multiple spaced intervals.

**What:** Require at least 2 successful reviews on different calendar days before promoting past box 2.

**Implementation:**
- In `SchedulingService.processGrade()`: When grade >= 3 and current box <= 2, check if the card has been successfully reviewed (grade >= 3) on a *different calendar day* before. If not, keep in current box but still update `nextReviewDate` to the current box's interval (forces another spaced review).
- Query `SessionResponse` for the card to check historical grades + dates.
- Box 3+ promotions work as normal (the intervals are already long enough to be meaningful).

**Files to modify:**
- `SchedulingService.swift` (add promotion guard logic)

---

### 7. Flexible Review — Practice When Nothing Is Due
**Principle:** Users should always be able to study, even if no cards are technically "due." Motivation matters.

**What:** When no cards are due, offer a "Practice Anyway" option that lets users review cards ahead of schedule without disrupting their Leitner box progression.

**Implementation:**
- In `FlashcardsViewController.viewAllFlashcards()`: When `dueCards.isEmpty`, instead of just showing "nothing due" alert, offer "Practice Anyway" which fetches cards sorted by `nextReviewDate` ascending (soonest-due first).
- **Key:** These "early practice" sessions should NOT advance Leitner boxes or reset `nextReviewDate`. They're reinforcement without scheduling impact. The user gets to practice, but the spaced repetition algorithm isn't disrupted.
- Add a flag on StudySessionViewController: `isEarlyPractice: Bool`. When true, skip `processGrade()` calls. Still show feedback and grades for learning value, just don't update scheduling.
- Show a subtle indicator in the session ("Early practice — scheduling not affected").

**Files to modify:**
- `FlashcardsViewController.swift` (offer early practice when nothing due)
- `StudySessionViewController.swift` (add `isEarlyPractice` flag, conditionally skip grade processing)
- `SchedulingService.swift` (add method to fetch non-due cards sorted by next review date)

---

### 8. Elaboration Bridge Cards
**Principle:** Elaboration — connecting new knowledge to existing knowledge — creates more retrieval cues and deeper understanding.

**What:** During AI card generation, also generate cross-concept bridge cards that ask "How does Concept A relate to Concept B?"

**Implementation:**
- Modify `ClaudePromptTemplates.defaultCardGenerationSystem` to include a new card type: `elaboration_bridge` (Tier 2). The prompt should instruct Claude to generate 1 bridge card for every pair of related concepts (using the `relatedConcepts` data already extracted in Phase 1).
- Bridge card format: Front = "Explain the relationship between [A] and [B]", with appropriate rubric, model answer, and bullet points.
- These cards have `dependsOnCards` pointing to the T1 cards of both concepts, so they unlock when both foundation concepts are mastered.
- Add `"elaboration_bridge"` to the recognized card types in `AICardGenerationService`.

**Files to modify:**
- `ClaudePromptTemplates.swift` (update card generation prompt to include bridge cards)
- `AICardGenerationService.swift` (handle new card type)
- `SchedulingService.swift` (recognize `elaboration_bridge` as valid Tier 2 type if needed)

---

### 9. Confidence Self-Assessment
**Principle:** Metacognition — knowing what you know and don't know — is itself a learnable skill. Tracking confidence vs. actual grade reveals calibration gaps.

**What:** After answering each card (before seeing the grade), ask "How confident are you?" with a simple 3-point scale (Low / Medium / High).

**Implementation:**
- **Core Data Model 5:** Add `confidence: Int16 (optional, default 0)` to `SessionResponse` entity. Values: 1=Low, 2=Medium, 3=High, 0=not recorded.
- **StudySessionViewController:** After user submits answer, show a quick confidence picker (3 buttons) before moving to next card. Store alongside the answer.
- **SessionResultsViewController:** Flag "miscalibrated" cards where confidence was High but grade was low (or vice versa). Show a calibration indicator.
- **DashboardViewController:** Show overall calibration score (correlation between confidence and grades over time).
- **Future consideration:** Factor confidence into scheduling — high-confidence wrong answers could get shorter review intervals (the user thinks they know it but doesn't, which is dangerous for retention).

**Files to modify:**
- `Model.xcdatamodeld/` (Model 5 — add confidence to SessionResponse)
- `SessionResponse+CoreDataProperties.swift`
- `StudySessionViewController.swift` (add confidence picker UI after answer)
- `SessionResultsViewController.swift` (show calibration flags)
- `DashboardViewController.swift` (calibration metrics)

---

### 10. Hints for Struggling Users
**Principle:** Desirable difficulty — retrieval should be effortful but not impossible. Graduated scaffolding prevents demoralization.

**What:** Add a "Hint" button during card answering that reveals partial information (first letters of keywords, one bullet point, or a category cue) to help the user retrieve the answer.

**Implementation:**
- **StudySessionViewController:** Add a "Need a hint?" button. First tap shows a mild hint (category or first letter of key terms from `gradingRubric.mustContainKeywords`). Second tap shows a stronger hint (one bullet point from the answer).
- Track hint usage per card in the session (store as part of the answer data).
- **Grading consideration:** Pass hint usage to AIGradingService so the grader can account for it (optional — could also just let the grade reflect answer quality regardless).
- Hints don't need Core Data changes — just tracked in-memory during the session and optionally noted in `SessionResponse.userAnswer` metadata.

**Files to modify:**
- `StudySessionViewController.swift` (add hint button, hint generation logic, track usage)
- `AIGradingService.swift` (optionally note hint usage in grading prompt)

---

### 11. Spaced Review of Source Notes (Lower Priority)
**Principle:** Re-study after failed retrieval is more effective than re-study alone.

**What:** When a user struggles with cards from a particular section of their notes, prompt them to re-read that section.

**Implementation details to be discussed closer to implementation time.** Depends on items 2 (stored source notes) and 5 (dashboard) being complete first. Likely involves:
- Linking cards to approximate positions in source notes (via `sourceRefs`)
- After a session with poor results, offering "Review the relevant notes?" with the appropriate section highlighted
- This is the most speculative item and may evolve based on how the other features feel in practice.

---

## Core Data Migration Summary (Model 5)

All schema changes consolidated into a single migration:

| Entity | Change |
|--------|--------|
| **Group (NEW)** | `groupID: String`, `groupName: String`, `createdAt: Date`, `decks: [Deck]` (one-to-many) |
| **Deck** | Add `sourceNotes: String?`, add `group: Group?` (many-to-one inverse) |
| **StudySession** | Add `group: Group?` (many-to-one), add `isEarlyPractice: Bool` (default false) |
| **SessionResponse** | Add `confidence: Int16` (default 0) |

All additions are optional/defaulted → lightweight migration compatible.

---

## Verification Plan

After each item is implemented:
1. **Build in Xcode** — confirm no compile errors
2. **Run on simulator** — walk through the affected flow end-to-end
3. **Core Data migration** — verify existing data loads without crash after Model 5 migration
4. **Test interleaving** — create a group with 2+ decks, practice, confirm cards shuffle across decks
5. **Test source notes** — generate a deck from notes, verify notes are stored and viewable
6. **Test text input** — type an answer, submit, confirm it grades correctly
7. **Test scheduling** — verify cards shuffle within sessions, minimum spacing blocks premature promotion, early practice doesn't affect Leitner boxes
