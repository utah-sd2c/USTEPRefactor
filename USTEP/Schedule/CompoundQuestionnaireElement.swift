//
// This source file is part of the USTEP based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import ResearchKit
import SpeziQuestionnaire

///
/// This class represents a Spezi questionnaire that has added ORKSteps inserted in at specific indexes
///
public class CompoundQuestionnaireElement {
    /// The Spexi questionnaire to use as the base for this compoud questionnaire
    public let questionnaire: Questionnaire
    /// The steps to add and the indexes at which to add them
    public let stepsToInsert: [Int: [ORKStep]]
    
    /// Creates a new compound questionnaire
    public init(questionnaire: Questionnaire, stepsToInsert: [Int: [ORKStep]]) {
        self.questionnaire = questionnaire
        self.stepsToInsert = stepsToInsert
    }
}
