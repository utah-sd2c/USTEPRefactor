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
    case videoInstruction, getUpAndGo, sixMWT, completion
}

public class CodableORKStep: Codable, Equatable {
    public static func == (lhs: CodableORKStep, rhs: CodableORKStep) -> Bool {
        return lhs.stepType == rhs.stepType &&
            lhs.id == rhs.id &&
            lhs.title == rhs.title &&
            lhs.text == rhs.text &&
            lhs.url == rhs.url
    }
    
    public var stepType: CodableORKStepType
    public var id: String
    public var title: String
    public var text: String
    public var url: String
    
    public init(stepType: CodableORKStepType, id: String, title: String, text: String, url: String = "") {
        self.stepType = stepType
        self.id = id
        self.title = title
        self.text = text
        self.url = url
    }
    
    public static func createORKStep(codableORKStep: CodableORKStep) -> ORKStep {
        switch codableORKStep.stepType {
        case .videoInstruction:
            let videoInstructionStep = ORKVideoInstructionStep(identifier: codableORKStep.id)
            videoInstructionStep.title = codableORKStep.title
            videoInstructionStep.text = codableORKStep.text
            videoInstructionStep.videoURL = URL(string: codableORKStep.url)
            return videoInstructionStep
        case .getUpAndGo:
            let getUpAndGoStep = GetUpAndGoStep(identifier: codableORKStep.id)
            getUpAndGoStep.title = codableORKStep.title
            getUpAndGoStep.text = codableORKStep.text
            return getUpAndGoStep
        case .sixMWT:
            let activeStep = ORKActiveStep(identifier: codableORKStep.id)
            activeStep.title = codableORKStep.title
            activeStep.text = codableORKStep.text
            return activeStep
        case .completion:
            let completionStep = ORKCompletionStep(identifier: codableORKStep.id)
            completionStep.title = codableORKStep.title
            completionStep.text = codableORKStep.text
            return completionStep
        }
    }
}

public struct CodableORKSteps: Codable, Equatable {
    public static func == (lhs: CodableORKSteps, rhs: CodableORKSteps) -> Bool {
        return lhs.codableORKSteps == rhs.codableORKSteps
    }
    
    public var codableORKSteps: [CodableORKStep]
    
    public init() {
        codableORKSteps = []
    }
}

public struct CodableORKStepsDict: Codable, Equatable {
    public static func == (lhs: CodableORKStepsDict, rhs: CodableORKStepsDict) -> Bool {
        return lhs.dict == rhs.dict
    }
    
    public var dict: [Int: CodableORKSteps]
    
    public init() {
        dict = [:]
    }
}

public struct CodableTitleMapDict: Codable, Equatable {
    public static func == (lhs: CodableTitleMapDict, rhs: CodableTitleMapDict) -> Bool {
        return lhs.dict == rhs.dict
    }
    
    public var dict: [String: String]
    
    public init() {
        dict = [:]
    }
}

public class CompoundQuestionnaire: Codable, Equatable {
    enum CodingKeys: String, CodingKey {
        case stepsToInsert, questionnaire, titleOverrides
    }
    
    public var stepsToInsert: CodableORKStepsDict
    public var questionnaire: Questionnaire
    public var titleOverrides: CodableTitleMapDict
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.stepsToInsert = try container.decode(CodableORKStepsDict.self, forKey: .stepsToInsert)
        self.questionnaire = try container.decode(Questionnaire.self, forKey: .questionnaire)
        self.titleOverrides = try container.decode(CodableTitleMapDict.self, forKey: .titleOverrides)
    }
    
    public init(questionnaire: Questionnaire, stepsToInsert: CodableORKStepsDict, titleOverrides: CodableTitleMapDict = CodableTitleMapDict()) {
        self.stepsToInsert = stepsToInsert
        self.questionnaire = questionnaire
        self.titleOverrides = titleOverrides
    }
    
    public static func == (lhs: CompoundQuestionnaire, rhs: CompoundQuestionnaire) -> Bool {
        return lhs.questionnaire == rhs.questionnaire && lhs.stepsToInsert == rhs.stepsToInsert && lhs.titleOverrides == rhs.titleOverrides
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(stepsToInsert, forKey: .stepsToInsert)
        try container.encode(questionnaire, forKey: .questionnaire)
        try container.encode(titleOverrides, forKey: .titleOverrides)
    }
}
