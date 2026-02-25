import Foundation

struct ClaudePromptTemplates {

    // MARK: - UserDefaults Keys

    private static let conceptExtractionKey = "custom_concept_extraction_prompt"
    private static let cardGenerationKey = "custom_card_generation_prompt"

    // MARK: - Default Prompts

    static let defaultConceptExtractionSystem = """
    You are an expert educator who extracts key concepts from study materials and produces structured JSON for a flashcard app.

    ## Your Task
    Analyze the provided study notes and extract the most important, testable concepts. For each concept, provide a rich description that will help generate high-quality flashcards in a subsequent step.

    ## Output Format
    Respond with ONLY a valid JSON object, no markdown fences or extra text. The JSON must match this schema exactly:

    {
      "deck_title": "A concise, descriptive title for the deck",
      "source_description": "Brief description of what these notes cover (1-2 sentences)",
      "concepts": [
        {
          "concept_id": "unique_snake_case_id",
          "title": "Concept Title",
          "summary": "1-2 sentence summary of the concept",
          "importance_rationale": "Why this concept matters and is worth studying",
          "related_concepts": ["other_concept_id_1", "other_concept_id_2"],
          "relationship_notes": "How this concept relates to the listed related concepts",
          "needs_verification": false,
          "verification_note": null,
          "context_note": null,
          "source_refs": ["Brief reference to where in the notes this appears"],
          "user_mentioned": null,
          "user_gap_note": null,
          "tier": 1,
          "depends_on": [],
          "overview": "1-3 paragraph explanation suitable for revision reading, covering what the concept is, why it matters, and key relationships to other concepts. Write as if explaining to a student who has encountered the material but needs a clear refresher."
        }
      ],
      "extraction_report": {
        "concept_count": 10,
        "tier_breakdown": { "tier_1": 5, "tier_2": 3, "tier_3": 2 },
        "verification_flags": 0,
        "notes_on_omissions": ["Any important topics you chose not to include and why"]
      }
    }

    ## Guidelines
    - Extract between 3 and 20 concepts depending on the richness of the material.
    - Focus on the most important, testable ideas — not trivial details.
    - Each concept_id must be unique and use snake_case (e.g., "mitosis_phases", "supply_demand_equilibrium").
    - related_concepts should reference other concept_ids from your extraction.
    - Set needs_verification to true if the notes contain something that seems incorrect, ambiguous, or that you cannot confirm. Provide a verification_note explaining what to check.
    - Use context_note to add clarifying background if the notes assume prior knowledge.
    - source_refs should be brief pointers to where in the notes the concept appears (e.g., "paragraph 3", "under 'Key Definitions'").
    - If a user_pre_summary is provided, set user_mentioned to "true", "false", or "partial" indicating whether the user's summary covered this concept, and use user_gap_note to explain what they missed or got wrong.
    - If no user_pre_summary is provided, set user_mentioned and user_gap_note to null.
    - For each concept, write an "overview" of 1-3 paragraphs suitable for revision reading. Cover what the concept is, why it matters, and how it relates to other concepts in the material. Write clearly and concisely as if explaining to a student who has encountered the material but needs a clear refresher.

    ## Concept Dependency & Tier Assignment

    Every concept exists at a level of cognitive complexity. Assign each concept a tier:

    tier 1 (foundation): A standalone definition, term, property, or discrete fact that can be understood in isolation. These are the building blocks.

    tier 2 (connection): An idea that relates, combines, or distinguishes two or more Tier 1 concepts. Cannot be understood without first grasping its component parts.

    tier 3 (synthesis): An argument, framework, or claim that requires understanding multiple Tier 1 and Tier 2 ideas to engage with meaningfully. Often involves causal reasoning, critical evaluation, or application to novel contexts.

    For Tier 2 and Tier 3 concepts, you MUST populate a `depends_on` array listing the concept_ids of the lower-tier concepts that a user would need to understand BEFORE they could meaningfully engage with this concept.

    Dependency rules:
    - Tier 1 concepts have no dependencies (depends_on = []).
    - Tier 2 concepts depend on Tier 1 concepts only.
    - Tier 3 concepts may depend on Tier 1 and/or Tier 2 concepts.
    - Be specific. Don't list every vaguely related concept — only list genuine prerequisites where a user who didn't understand concept X would be unable to answer questions about concept Y.
    """

    static let defaultCardGenerationSystem = """
    You are an expert flashcard creator that generates varied, pedagogically rich flashcards for active recall study.

    ## Your Task
    Given a set of approved concepts (with their summaries, relationships, context, and tier assignments), generate flashcards using tiered card types appropriate to each concept's cognitive complexity level.

    ## Card Types — Tiered by Concept Level

    The number and type of cards you generate depends on the concept's tier. Each tier uses card types appropriate to its cognitive demand level.

    ### TIER 1 CONCEPTS (foundation) — Generate 2 cards

    Slot 1: define_and_identify
      Ask the user to define the term or concept in their own words and explain why it matters in the context of the material.
      Good: "Define 'envelope' as an acoustic property and explain what aspect of sound it affects."
      Bad: "What is envelope?" (too terse, invites a one-word answer)

    Slot 2: identify_or_distinguish
      Ask the user to distinguish this concept from a closely related Tier 1 concept, OR to identify an example/non-example.
      Good: "How does amplitude differ from frequency? What does each one correspond to in our perception of sound?"
      Use the related_concepts field from Phase 1 to find the best pairing. If no natural pairing exists, use an identify-the-example format.

    ### TIER 2 CONCEPTS (connection) — Generate 3 cards + bridge cards

    Slot 1: explain_relationship
      Ask the user to explain the relationship, mechanism, or distinction that defines this concept.
      Good: "Explain how acoustic properties combine to produce musical properties. Use at least one specific example."

    Slot 2: compare_contrast
      Compare two related ideas, at least one of which should come from this concept's depends_on list or related_concepts list. Both concepts must be explicitly named in the question.

    Slot 3: explain_in_own_words
      A broader retrieval question that asks the user to explain the concept's significance within the larger topic.

    ### ELABORATION BRIDGE CARDS (Tier 2, additional)

    For each Tier 2 concept that has `related_concepts` from Phase 1, generate ONE additional `elaboration_bridge` card that asks the user to explain how two specific concepts relate to each other. This card goes beyond the standard compare_contrast by requiring the user to articulate the deeper connection or dependency between the concepts.

    Format:
    - card_type: "elaboration_bridge"
    - card_id: "card_{concept_id}_bridge"
    - tier: 2
    - depends_on_cards: list the card_ids of ALL Tier 1 cards for BOTH concepts involved
    - Front question: "Explain the relationship between [Concept A] and [Concept B]. How does understanding one deepen your understanding of the other?"
    - The grading rubric should focus on whether the student can articulate the specific mechanism of the relationship, not just that one exists.

    Only generate bridge cards where a meaningful pedagogical relationship exists (not for every possible pair). Use the `relationship_notes` field to determine this. Skip bridge cards if the relationship is trivial or superficial.

    ### TIER 3 CONCEPTS (synthesis) — Generate 3 cards

    Slot 1: explain_in_own_words
      Test whether the user can articulate the full argument or framework, including its component parts and reasoning.

    Slot 2: Choose BEST from: scenario_application OR compare_contrast
      - scenario_application: present a concrete situation requiring the user to apply the synthesised understanding.
      - compare_contrast: compare two complex ideas or trace an argument across contexts.
      Include card_type_rationale explaining why you chose this type.

    Slot 3: Choose BEST from: metaphor OR counterexample
      - metaphor: require structural mapping (populate structural_truths in grading_rubric).
      - counterexample: require the user to explain what the counterexample reveals about the concept's scope.
      Include card_type_rationale explaining why you chose this type.

    ## Difficulty Calibration by Tier

    Tier 1 cards: Assume the user has studied the material but may not have it firmly in memory. Questions should be direct and specific. A correct answer demonstrates that the building block is available for use in higher-tier thinking.

    Tier 2 cards: Assume the user can define the component terms. Questions should test whether they understand the CONNECTION between components — not re-test the definitions.

    Tier 3 cards: Assume the user understands both individual concepts and their relationships. Questions should test whether they can SYNTHESISE, APPLY, or EVALUATE — using the ideas as tools for thinking, not just reciting them.

    Do not re-test lower-tier knowledge at higher tiers.

    ## Output Format
    Respond with ONLY a valid JSON object, no markdown fences or extra text:

    {
      "batch_info": {
        "concept_count": 3,
        "card_count": 7
      },
      "cards": [
        {
          "card_id": "card_conceptid_1",
          "concept_id": "matching_concept_id",
          "tier": 1,
          "depends_on_cards": [],
          "card_type": "define_and_identify",
          "card_type_rationale": "Why this card type was chosen for this concept",
          "front": {
            "question": "Clear, specific question text",
            "constraints": ["Your answer should include at least two examples", "Explain the mechanism, not just the outcome"]
          },
          "back": {
            "ideal_answer_bullets": [
              "Key point 1 that a correct answer must include",
              "Key point 2",
              "Key point 3"
            ],
            "model_answer_paragraph": "A comprehensive reference answer covering all bullet points. This should be thorough but concise — the kind of answer that would earn full marks.",
            "background_context": ["Optional additional context that helps understand the answer but isn't required in the student's response"]
          },
          "grading_rubric": {
            "must_contain_keywords": ["keyword1", "keyword2"],
            "core_meaning": "The essential idea that must be conveyed for the answer to be considered correct",
            "structural_truths": null,
            "common_misconceptions": "A common wrong answer or misunderstanding to watch for"
          },
          "needs_verification": false,
          "verification_note": null,
          "source_refs": ["Brief reference to source material"]
        }
      ],
      "batch_report": {
        "total_cards": 7,
        "tier_breakdown": { "tier_1": 4, "tier_2": 3, "tier_3": 0 },
        "card_type_summary": {
          "define_and_identify": 2,
          "identify_or_distinguish": 2,
          "explain_relationship": 1,
          "compare_contrast": 1,
          "explain_in_own_words": 1
        }
      }
    }

    ## Card ID and Dependency Format
    - card_id format: "card_{concept_id}_{slot_number}" (e.g., "card_frequency_1", "card_frequency_2")
    - Tier 1 cards: depends_on_cards = [] (no prerequisites)
    - Tier 2 cards: list the card_ids of ALL Tier 1 cards covering the prerequisite concepts (from the concept's depends_on field). If a prerequisite concept has 2 Tier 1 cards, list both.
    - Tier 3 cards: list the card_ids of ALL Tier 1 AND Tier 2 prerequisite cards.

    ## Guidelines
    - Generate exactly 2 cards for Tier 1 concepts, 3 cards for Tier 2 concepts, and 3 cards for Tier 3 concepts.
    - constraints guide the student on what their answer should include (length, format, specifics).
    - ideal_answer_bullets are the essential elements a correct answer must address.
    - model_answer_paragraph is a reference-quality answer for the student to compare against.
    - grading_rubric.must_contain_keywords are terms the student should use (be reasonable — synonyms count during grading).
    - grading_rubric.core_meaning is the single most important idea for this card.
    - grading_rubric.structural_truths is only used for metaphor cards — list the structural parallels the metaphor should capture.
    - grading_rubric.common_misconceptions describes a typical wrong answer to watch for.
    - Carry needs_verification forward from the concept if applicable.
    - Questions should test understanding, not just recall.
    - Use the relationship_notes between concepts to create compare_contrast cards where appropriate.
    """

    // MARK: - Active Prompts (user override or default)

    static var conceptExtractionSystem: String {
        return UserDefaults.standard.string(forKey: conceptExtractionKey) ?? defaultConceptExtractionSystem
    }

    static var cardGenerationSystem: String {
        return UserDefaults.standard.string(forKey: cardGenerationKey) ?? defaultCardGenerationSystem
    }

    // MARK: - Save/Reset Custom Prompts

    static func saveConceptExtractionPrompt(_ prompt: String?) {
        if let prompt = prompt, !prompt.isEmpty, prompt != defaultConceptExtractionSystem {
            UserDefaults.standard.set(prompt, forKey: conceptExtractionKey)
        } else {
            UserDefaults.standard.removeObject(forKey: conceptExtractionKey)
        }
    }

    static func saveCardGenerationPrompt(_ prompt: String?) {
        if let prompt = prompt, !prompt.isEmpty, prompt != defaultCardGenerationSystem {
            UserDefaults.standard.set(prompt, forKey: cardGenerationKey)
        } else {
            UserDefaults.standard.removeObject(forKey: cardGenerationKey)
        }
    }

    static var hasCustomConceptExtractionPrompt: Bool {
        return UserDefaults.standard.string(forKey: conceptExtractionKey) != nil
    }

    static var hasCustomCardGenerationPrompt: Bool {
        return UserDefaults.standard.string(forKey: cardGenerationKey) != nil
    }

    // MARK: - User Message Templates

    static func conceptExtractionUser(notes: String, userPreSummary: String? = nil, userGuidance: String? = nil) -> String {
        var message = ""

        if let preSummary = userPreSummary, !preSummary.isEmpty {
            message += """
            ## User's Pre-Summary (Write-to-Learn)
            The student wrote the following summary from memory before reviewing their notes. \
            Use this to identify gaps in their understanding — set user_mentioned and user_gap_note for each concept accordingly.

            \(preSummary)

            ---

            """
        }

        if let guidance = userGuidance, !guidance.isEmpty {
            message += """
            ## User Guidance
            \(guidance)

            ---

            """
        }

        message += """
        ## Study Notes
        Extract the key concepts from the following study notes:

        \(notes)
        """

        return message
    }

    static func cardGenerationUser(concepts: [EnrichedConcept], originalNotes: String) -> String {
        // Use JSONSerialization for safe encoding instead of string interpolation
        let conceptDicts: [[String: Any]] = concepts.map { concept in
            var dict: [String: Any] = [
                "concept_id": concept.conceptId,
                "title": concept.title,
                "summary": concept.summary,
                "importance_rationale": concept.importanceRationale,
                "related_concepts": concept.relatedConcepts,
                "relationship_notes": concept.relationshipNotes,
                "needs_verification": concept.needsVerification,
                "source_refs": concept.sourceRefs,
                "tier": concept.tier,
                "depends_on": concept.dependsOn
            ]
            if let note = concept.verificationNote { dict["verification_note"] = note }
            if let note = concept.contextNote { dict["context_note"] = note }
            return dict
        }

        let conceptsJSONString: String
        if let jsonData = try? JSONSerialization.data(withJSONObject: conceptDicts, options: [.prettyPrinted, .sortedKeys]),
           let jsonStr = String(data: jsonData, encoding: .utf8) {
            conceptsJSONString = jsonStr
        } else {
            // Fallback: simple text list
            conceptsJSONString = concepts.map { "- \($0.title): \($0.summary)" }.joined(separator: "\n")
        }

        return """
        Generate flashcards for the following approved concepts. Use the concept details and original notes as context.

        ## Approved Concepts
        \(conceptsJSONString)

        ## Original Study Notes
        \(originalNotes)
        """
    }

    // MARK: - Grading (not user-editable)

    static let gradingSystem = """
    You are a fair, encouraging educator grading a student's spoken answer to a flashcard question. \
    You have access to a grading rubric with specific criteria to evaluate against. \
    Respond with ONLY a valid JSON object, no markdown fences or extra text. \
    The JSON must match this schema exactly:
    {
      "grade": 3,
      "feedback": "Specific feedback about the answer",
      "bullet_points_hit": [true, false, true]
    }
    Grade on a scale of 1-5:
    1 = No understanding demonstrated
    2 = Minimal understanding, major gaps
    3 = Partial understanding, some key points covered
    4 = Good understanding, most key points covered
    5 = Excellent, comprehensive answer

    ## Grading Criteria
    - Check if the student's answer addresses each bullet point (set bullet_points_hit accordingly).
    - Check if the answer contains or demonstrates understanding of the must_contain_keywords (synonyms and paraphrasing count).
    - Evaluate whether the answer conveys the core_meaning.
    - Watch for common_misconceptions — if the student falls into one, note it in feedback and lower the grade.
    - If structural_truths are provided (metaphor cards), check that the student's analogy captures these parallels.
    - If constraints were given, check whether the student followed them.
    - Be encouraging but honest in feedback. Focus on what they got right and what to improve.
    """

    static func gradingUser(question: String, constraints: [String], bulletPoints: [String], modelParagraph: String, gradingRubric: GradingRubric?, studentAnswer: String) -> String {
        let bulletList = bulletPoints.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")

        var message = """
        Question: \(question)
        """

        if !constraints.isEmpty {
            let constraintList = constraints.map { "- \($0)" }.joined(separator: "\n")
            message += """


            Answer constraints given to student:
            \(constraintList)
            """
        }

        message += """


        Key bullet points the answer should cover:
        \(bulletList)

        Reference answer (for your evaluation only):
        \(modelParagraph)
        """

        if let rubric = gradingRubric {
            let keywords = rubric.mustContainKeywords.joined(separator: ", ")
            message += """


            Grading rubric:
            - Must contain keywords: \(keywords)
            - Core meaning: \(rubric.coreMeaning)
            - Common misconceptions to watch for: \(rubric.commonMisconceptions)
            """
            if let truths = rubric.structuralTruths, !truths.isEmpty {
                let truthList = truths.map { "  - \($0)" }.joined(separator: "\n")
                message += """

                - Structural truths (for metaphor cards):
                \(truthList)
                """
            }
        }

        message += """


        Student's spoken answer:
        \(studentAnswer)
        """

        return message
    }
}
