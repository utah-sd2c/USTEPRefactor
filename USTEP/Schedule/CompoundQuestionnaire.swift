//
// This source file is part of the USTEP based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import ResearchKit
import SpeziQuestionnaire

public class CompoundQuestionnaire: Questionnaire {
    public var stepsToInsert: [Int: [ORKStep]] = [:]
    
    public init(questionnaire: Questionnaire, stepsToInsert: [Int: [ORKStep]]) {
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
        // self.stepsToInsert = [:]
        try super.init(from: decoder)
    }
}
