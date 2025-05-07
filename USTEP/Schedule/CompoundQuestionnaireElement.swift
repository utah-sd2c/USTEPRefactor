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
/// Documentation
///
public class CompoundQuestionnaireElement {
    /// Documentation
    public let questionnaire: Questionnaire
    /// Documentation
    public let stepsToInsert: [Int: [ORKStep]]
    
    /// Documentation here too
    public init(questionnaire: Questionnaire, stepsToInsert: [Int: [ORKStep]]) {
        self.questionnaire = questionnaire
        self.stepsToInsert = stepsToInsert
    }
}
