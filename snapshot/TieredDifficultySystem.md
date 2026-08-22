# Tiered Difficulty System — Additions to Flashcard Generation

This document describes what to ADD to the existing Phase 1 prompt, Phase 2 prompt, and app logic. Nothing is removed — these are additive changes only.

---

## The Model: Three Tiers of Cognitive Demand

### Tier 1 — Foundation (Recall & Define)
Can the user identify, define, and describe individual building blocks?
- "What is frequency?"
- "What does the term 'emergence' mean in the context of this course's definition of music?"
- "Name the three acoustic properties."

These are the atoms. They test whether key terms, definitions, and isolated facts are in memory. A user who can't answer Tier 1 cards has no business attempting Tier 2 or 3.

### Tier 2 — Connection (Relate & Distinguish)
Can the user explain how building blocks relate to each other?
- "How do acoustic properties give rise to musical properties?"
- "What is the difference between sound and music according to the lecturer?"
- "How does the concept of intentionality relate to the course's working definition of music?"

These require holding two or more Tier 1 ideas in mind simultaneously and articulating the relationship.

### Tier 3 — Synthesis (Apply, Analyse & Evaluate)
Can the user use interconnected ideas in novel contexts?
- "Propose a metaphor for the gradient perspective on animal musicality. What maps to what?"
- "A colonial power conquers a region with a rich bardic tradition. Predict what happens to the musicians and why."
- "Identify a counterexample to the claim that music requires intentionality, and explain what it reveals about the definition's limitations."

These are the existing complex card types (metaphor, counterexample, scenario_application, and the more demanding compare_contrast questions). They require the user to have internalised both individual concepts AND their relationships before they can synthesise.

---

## Phase 1 Prompt Additions

Add the following section to the Phase 1 prompt, after the existing GRANULARITY RULE section:

```
────────────────────────────────────────
CONCEPT DEPENDENCY & TIER ASSIGNMENT
────────────────────────────────────────

Every concept exists at a level of cognitive complexity. Assign each concept a tier:

  tier 1 (foundation): A standalone definition, term, property, or discrete fact
    that can be understood in isolation. These are the building blocks.
    Examples: "frequency," "amplitude," "envelope," "intentionality."

  tier 2 (connection): An idea that relates, combines, or distinguishes
    two or more Tier 1 concepts. Cannot be understood without first
    grasping its component parts.
    Examples: "acoustic properties combine to create musical properties,"
    "the distinction between sound and music."

  tier 3 (synthesis): An argument, framework, or claim that requires
    understanding multiple Tier 1 and Tier 2 ideas to engage with
    meaningfully. Often involves causal reasoning, critical evaluation,
    or application to novel contexts.
    Examples: "music as a vehicle for power and control,"
    "the impact of recording technology on musical engagement,"
    "the course's working definition of music."

For Tier 2 and Tier 3 concepts, you MUST populate a `depends_on` array
listing the concept_ids of the lower-tier concepts that a user would need
to understand BEFORE they could meaningfully engage with this concept.

Dependency rules:
- Tier 1 concepts have no dependencies (depends_on = []).
- Tier 2 concepts depend on Tier 1 concepts only.
- Tier 3 concepts may depend on Tier 1 and/or Tier 2 concepts.
- Be specific. Don't list every vaguely related concept — only list
  genuine prerequisites where a user who didn't understand concept X
  would be unable to answer questions about concept Y.
```

Add these fields to the concept object in the JSON schema:

```json
{
  "concept_id": "c_01",
  "title": "...",
  "tier": 1,
  "depends_on": [],
  // ... all existing fields remain unchanged
}
```

Add to the `extraction_report`:

```json
{
  "concept_count": 0,
  "tier_breakdown": { "tier_1": 0, "tier_2": 0, "tier_3": 0 },
  "verification_flags": 0,
  "notes_on_omissions": []
}
```

---

## Phase 2 Prompt Additions

Replace the existing CARD TYPES section with the following expanded version:

```
────────────────────────────────────────
CARD TYPES — TIERED BY CONCEPT LEVEL
────────────────────────────────────────

The number and type of cards you generate depends on the concept's tier.
Each tier uses card types appropriate to its cognitive demand level.

━━━ TIER 1 CONCEPTS (foundation) — Generate 2 cards ━━━

  Slot 1: define_and_identify
    Ask the user to define the term or concept in their own words and
    explain why it matters in the context of the material.
    Good: "Define 'envelope' as an acoustic property and explain what
    aspect of sound it affects."
    Bad: "What is envelope?" (too terse, invites a one-word answer)

  Slot 2: identify_or_distinguish
    Ask the user to distinguish this concept from a closely related
    Tier 1 concept, OR to identify an example/non-example.
    Good: "How does amplitude differ from frequency? What does each
    one correspond to in our perception of sound?"
    Use the related_concepts field from Phase 1 to find the best
    pairing. If no natural pairing exists, use an identify-the-example
    format: "Which acoustic property determines whether a sound is
    perceived as a flute vs a trumpet playing the same note?"

━━━ TIER 2 CONCEPTS (connection) — Generate 3 cards ━━━

  Slot 1: explain_relationship
    Ask the user to explain the relationship, mechanism, or distinction
    that defines this concept.
    Good: "Explain how acoustic properties combine to produce musical
    properties. Use at least one specific example."

  Slot 2: compare_contrast
    Compare two related ideas, at least one of which should come from
    this concept's depends_on list or related_concepts list.
    Both concepts must be explicitly named in the question.
    Good: "Compare 'sound' and 'music' as defined in this course.
    What is the key factor that separates them?"

  Slot 3: explain_in_own_words
    A broader retrieval question that asks the user to explain the
    concept's significance within the larger topic.
    Good: "In your own words, explain why the lecturer argues it's
    important to think of musicality as a gradient rather than a
    binary. What does this perspective change?"

━━━ TIER 3 CONCEPTS (synthesis) — Generate 3 cards ━━━

  Slot 1: explain_in_own_words
    Test whether the user can articulate the full argument or
    framework, including its component parts and reasoning.
    Good: "Explain the argument that music functions as a vehicle
    for power and control. Include at least two historical examples
    from the notes and explain the mechanism by which control over
    music translates to control over people."

  Slot 2: Choose BEST from: scenario_application OR compare_contrast
    - scenario_application: present a concrete situation requiring
      the user to apply the synthesised understanding.
    - compare_contrast: compare two complex ideas or trace an
      argument across contexts.
    Include card_type_rationale.

  Slot 3: Choose BEST from: metaphor OR counterexample
    - metaphor: require structural mapping (structural_truths
      in grading_rubric).
    - counterexample: require the user to explain what the
      counterexample reveals about the concept's scope.
    Include card_type_rationale.

────────────────────────────────────────
DIFFICULTY CALIBRATION BY TIER
────────────────────────────────────────

  Tier 1 cards: Assume the user has studied the material but may not
  have it firmly in memory. Questions should be direct and specific.
  A correct answer demonstrates that the building block is available
  for use in higher-tier thinking.

  Tier 2 cards: Assume the user can define the component terms.
  Questions should test whether they understand the CONNECTION
  between components — not re-test the definitions.

  Tier 3 cards: Assume the user understands both individual concepts
  and their relationships. Questions should test whether they can
  SYNTHESISE, APPLY, or EVALUATE — using the ideas as tools for
  thinking, not just reciting them.

  Do not re-test lower-tier knowledge at higher tiers. If a Tier 3
  card about "music as power" implicitly requires knowing what
  "intentionality" means, the card should NOT ask the user to define
  intentionality — it should assume they know it and test whether
  they can use it in an argument.
```

Add `tier` and `depends_on_cards` to each card object in the JSON schema:

```json
{
  "card_id": "card_c01_1",
  "concept_id": "c_01",
  "tier": 1,
  "depends_on_cards": [],
  "card_type": "define_and_identify",
  // ... all existing fields remain unchanged
}
```

The `depends_on_cards` field works as follows:
- Tier 1 cards: always [] (no prerequisites).
- Tier 2 cards: list the card_ids of the Tier 1 cards covering the prerequisite concepts (derived from the concept's `depends_on` field in Phase 1). If the prerequisite concept has 2 Tier 1 cards, list both — the user should have mastered both before seeing this Tier 2 card.
- Tier 3 cards: list the card_ids of the Tier 1 AND Tier 2 prerequisite cards.

Update `batch_report`:

```json
{
  "cards_generated": 0,
  "tier_breakdown": { "tier_1": 0, "tier_2": 0, "tier_3": 0 },
  "cross_lecture_cards": 0,
  "notes": "..."
}
```

---

## App Implementation: Progressive Unlocking

### Core Mechanic

Cards are introduced progressively based on demonstrated mastery of prerequisites. The user never sees a card until its prerequisites are satisfied.

### Card States

Each card exists in one of these states:

- **locked**: Prerequisites not yet met. Card is invisible to the user.
- **available**: Prerequisites met. Card is in the active review queue.
- **learning**: Card has been attempted but not yet mastered (Leitner boxes 1-2).
- **mastered**: Card has been answered correctly across enough spaced intervals to indicate retention (Leitner box 3+, or whatever your mastery threshold is).

### Unlock Logic

```
When a card reaches "mastered" state:
  1. Find all cards where this card_id appears in depends_on_cards.
  2. For each found card:
     a. Check whether ALL of its depends_on_cards are now mastered.
     b. If yes → set that card's state to "available."
     c. If no → card remains "locked."
```

On first run (deck just created):
- All Tier 1 cards start as "available."
- All Tier 2 and Tier 3 cards start as "locked."

### What "Mastered" Means (Suggested Threshold)

A card is mastered when it has been answered correctly in at least 2 non-consecutive sessions (i.e., the user got it right, some time passed, and they got it right again). This aligns with the spaced repetition principle — a single correct answer doesn't demonstrate durable learning.

You can tune this threshold. More conservative = longer before complex cards unlock. Less conservative = faster progression but higher risk of the user hitting cards they're not ready for. Start with 2 correct answers across different sessions and adjust based on user feedback.

### Session Composition

When building a review session, draw from available and learning cards using these priorities:

1. **Due cards first**: Cards in "learning" state that are due for review per their Leitner schedule.
2. **New cards by tier**: When introducing new cards, prefer lower-tier available cards first. Don't introduce a Tier 2 card in the same session where its Tier 1 prerequisites were just unlocked — give the Tier 1 cards at least one review cycle first.
3. **Interleave by concept**: Don't present all cards from one concept consecutively. Mix concepts within a session for interleaved practice.
4. **Interleave by tier**: Within a session, alternate between tiers rather than doing all Tier 1 then all Tier 2. This prevents the session from feeling like it gets progressively harder and maintains varied practice.

### Dashboard Additions

The progress dashboard should reflect the tiered structure:

- Show a per-concept progress bar with three segments (Tier 1 / Tier 2 / Tier 3), each filling as cards are mastered.
- Show how many cards are locked vs available vs learning vs mastered, so the user can see their overall progression.
- Optionally show a "next unlock" indicator: "Master 1 more Tier 1 card to unlock 3 new cards."

### Edge Case: Approved Concepts with Missing Dependencies

If the user approves a Tier 2 concept but does NOT approve one of its Tier 1 dependencies (from Phase 1), the app should handle this gracefully:

- Option A (recommended): Auto-include unapproved dependency concepts at Tier 1 only (generate their Tier 1 cards as prerequisites but don't generate Tier 2/3 cards for them).
- Option B: Remove the dependency link and treat the Tier 2 card as having no prerequisites (less ideal — the user might encounter a card they're not ready for).

Flag this situation to the user: "Concept X depends on Concept Y, which you didn't select. We've added basic cards for Y as prerequisites."

---

## Updated Field Reference (Additions Only)

| Field | User-facing? | Sent to grading agent? | Used for scheduling? | Used for validation? |
|---|---|---|---|---|
| concept `tier` | ✅ Progress dashboard | ✗ | ✅ Unlock gating | ✅ Tier balance check |
| concept `depends_on` | ✗ (or optional graph) | ✗ | ✅ Unlock gating | ✅ Phase 2 input |
| card `tier` | ✅ Optional label | ✗ | ✅ Session composition | ✅ Tier balance check |
| card `depends_on_cards` | ✗ | ✗ | ✅ Unlock gating (core) | ✅ Dependency validation |
| `tier_breakdown` | ✅ Summary stat | ✗ | ✗ | ✅ Sanity check |

---

## Worked Example: How Tiers Flow

Given these concepts from the music lectures:

```
c_01: "Frequency" (Tier 1, depends_on: [])
c_02: "Amplitude" (Tier 1, depends_on: [])
c_03: "Envelope/Timbre" (Tier 1, depends_on: [])
c_04: "Acoustic properties combine to create musical properties" (Tier 2, depends_on: [c_01, c_02, c_03])
c_05: "Intentionality as the dividing line between sound and music" (Tier 2, depends_on: [c_04])
c_06: "The course's working definition of music" (Tier 3, depends_on: [c_04, c_05])
```

Cards generated:

```
Tier 1 (available immediately):
  card_c01_1: "Define frequency as an acoustic property..." (depends_on_cards: [])
  card_c01_2: "How does frequency differ from amplitude?" (depends_on_cards: [])
  card_c02_1: "Define amplitude..." (depends_on_cards: [])
  card_c02_2: "Distinguish amplitude from envelope..." (depends_on_cards: [])
  card_c03_1: "Define envelope/timbre..." (depends_on_cards: [])
  card_c03_2: "What perceptual quality does envelope determine?" (depends_on_cards: [])

Tier 2 (locked until Tier 1 mastered):
  card_c04_1: "Explain how acoustic properties give rise to musical properties..."
    (depends_on_cards: [card_c01_1, card_c01_2, card_c02_1, card_c02_2, card_c03_1, card_c03_2])
  card_c04_2: "Compare acoustic and musical properties..."
    (depends_on_cards: [card_c01_1, card_c01_2, card_c02_1, card_c02_2, card_c03_1, card_c03_2])
  card_c04_3: "In your own words, explain why the distinction matters..."
    (depends_on_cards: [card_c01_1, card_c01_2, card_c02_1, card_c02_2, card_c03_1, card_c03_2])

Tier 3 (locked until Tier 1 + Tier 2 mastered):
  card_c06_1: "Explain the course's working definition of music..."
    (depends_on_cards: [card_c04_1, card_c04_2, card_c04_3, card_c05_1, card_c05_2, card_c05_3])
  card_c06_2: "A comedian records audience laughter, pitches and arranges it..."
    (depends_on_cards: [...])
  card_c06_3: "Propose a metaphor for emergence in the context of music..."
    (depends_on_cards: [...])
```

User experience:
1. First session: sees only Tier 1 cards (definitions of frequency, amplitude, envelope).
2. After mastering those across 2+ sessions: Tier 2 cards unlock (how they combine, what distinguishes them).
3. After mastering Tier 2: Tier 3 cards unlock (the full working definition, application scenarios, metaphors).

The user is never thrown into a synthesis question before they can define the components they need to synthesise.