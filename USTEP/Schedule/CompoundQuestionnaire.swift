//
// This source file is part of the USTEP based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import ResearchKit
import SpeziQuestionnaire

public enum CodableORKStepType: String, Codable {
    case getUpAndGo, sixMWT, completion
}

public class CodableORKStep: Codable {
    public var stepType: CodableORKStepType
    public var id: String
    public var title: String
    public var text: String
    
    public init(stepType: CodableORKStepType, id: String, title: String, text: String) {
        self.stepType = stepType
        self.id = id
        self.title = title
        self.text = text
    }
    
    public static func createORKStep(codableORKStep: CodableORKStep) -> ORKStep {
        switch codableORKStep.stepType {
        case .getUpAndGo:
            var activeStep: ORKActiveStep = ORKActiveStep(identifier: codableORKStep.id)
            activeStep.title = codableORKStep.title
            activeStep.text = codableORKStep.text
            return activeStep
        case .sixMWT:
            var activeStep: ORKActiveStep = ORKActiveStep(identifier: codableORKStep.id)
            activeStep.title = codableORKStep.title
            activeStep.text = codableORKStep.text
            return activeStep
        case .completion:
            var completionStep: ORKCompletionStep = ORKCompletionStep(identifier: codableORKStep.id)
            completionStep.title = codableORKStep.title
            completionStep.text = codableORKStep.text
            return completionStep
        }
    }
}

public struct CodableORKSteps: Codable {
    public var codableORKSteps: [CodableORKStep]
    
    public init() {
        codableORKSteps = []
    }
}

public class CompoundQuestionnaire: Questionnaire {
    public var stepsToInsert: [Int: CodableORKSteps]
    
    public init(questionnaire: Questionnaire, stepsToInsert: [Int: CodableORKSteps]) {
        self.stepsToInsert = stepsToInsert
        super.init(status: questionnaire.status)
        self.approvalDate = questionnaire.approvalDate
        self.code = questionnaire.code
        self.contact = questionnaire.contact
        self.contained = questionnaire.contained
        self.copyright = questionnaire.copyright
        self.date = questionnaire.date
        self.derivedFrom = questionnaire.derivedFrom
        self.description_fhir = questionnaire.description_fhir
        self.effectivePeriod = questionnaire.effectivePeriod
        self.experimental = questionnaire.experimental
        self.`extension` = questionnaire.extension
        self.id = questionnaire.id
        self.identifier = questionnaire.identifier
        self.implicitRules = questionnaire.implicitRules
        self.item = questionnaire.item
        self.jurisdiction = questionnaire.jurisdiction
        self.language = questionnaire.language
        self.lastReviewDate = questionnaire.lastReviewDate
        self.meta = questionnaire.meta
        self.modifierExtension = questionnaire.modifierExtension
        self.name = questionnaire.name
        self.publisher = questionnaire.publisher
        self.purpose = questionnaire.purpose
        self.status = questionnaire.status
        self.subjectType = questionnaire.subjectType
        self.text = questionnaire.text
        self.title = questionnaire.title
        self.url = questionnaire.url
        self.useContext = questionnaire.useContext
        self.version = questionnaire.version
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeysForCompoundQuestionnaire.self)
        self.stepsToInsert = try container.decode([Int: CodableORKSteps].self, forKey: .stepsToInsert)
        try super.init(from: decoder)
    }
    
    enum CodingKeysForCompoundQuestionnaire: String, CodingKey {
        case stepsToInsert
    }
}
