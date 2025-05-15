//
// This source file is part of the USTEP based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import ResearchKit
import Spezi
import SpeziScheduler
import SpeziViews
import class ModelsR4.Questionnaire
import class ModelsR4.QuestionnaireResponse


@Observable
final class USTEPScheduler: Module, DefaultInitializable, EnvironmentAccessible {
    @Dependency(Scheduler.self) @ObservationIgnored private var scheduler

    @MainActor var viewState: ViewState = .idle

    init() {}
    
    /// Add or update the current list of task upon app startup.
    func configure() {
        do {
            try scheduler.createOrUpdateTask(
                id: "social-support-questionnaire",
                title: "Social Support Questionnaire",
                instructions: "Please fill out the Social Support Questionnaire every day.",
                category: .questionnaire,
                schedule: .daily(hour: 8, minute: 0, startingAt: .today)
            ) { context in
                var stepsToInsert: [Int: CodableORKSteps] = [:]
                var step0: CodableORKStep = .init(
                    stepType: .getUpAndGo,
                    id: "First step",
                    title: "First step",
                    text: "First step"
                )
                var step1: CodableORKStep = .init(
                    stepType: .sixMWT,
                    id: "Second step",
                    title: "Second step",
                    text: "Second step"
                )
                var firstSet: CodableORKSteps = .init()
                firstSet.codableORKSteps.append(step0)
                firstSet.codableORKSteps.append(step1)
                stepsToInsert.updateValue(firstSet, forKey: 1)
                var compStep: CodableORKStep = .init(
                    stepType: .completion,
                    id: "Completion step",
                    title: "Completion step",
                    text: "Completion step"
                )
                var secondSet: CodableORKSteps = .init()
                secondSet.codableORKSteps.append(compStep)
                stepsToInsert.updateValue(secondSet, forKey: -1) // -1 index forces the end of the array later on
                let compQuestionnaire = CompoundQuestionnaire(
                    questionnaire: Bundle.main.questionnaire(
                        withName: "SocialSupportQuestionnaire"
                    ),
                    stepsToInsert: stepsToInsert
                )
                context.compoundQuestionnaire = compQuestionnaire
            }
        } catch {
            viewState = .error(AnyLocalizedError(error: error, defaultErrorDescription: "Failed to create or update scheduled tasks."))
        }
    }
}


extension Task.Context {
    @Property(coding: .json) var compoundQuestionnaire: CompoundQuestionnaire?
}


extension Outcome {
    // periphery:ignore - demonstration of how to store additional context within an outcome
    @Property(coding: .json) var questionnaireResponse: QuestionnaireResponse?
}
