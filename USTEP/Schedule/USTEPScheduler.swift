//
// This source file is part of the USTEP based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable function_body_length
// swiftlint:disable closure_body_length
import Foundation
import ResearchKit
import Spezi
import SpeziQuestionnaire
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
                var stepsToInsert: CodableORKStepsDict = .init()
                let step0: CodableORKStep = .init(
                    stepType: .videoInstruction,
                    id: "getUpAndGoInstruction",
                    title: "Demonstration Above",
                    text: """
                    Click to Play

                    When you're ready to start, click Get Started
                    """,
                    url: "https://firebasestorage.googleapis.com/v0/b/ustep-refactor.firebasestorage.app/o/video.mp4?alt=media&token=5cb96d28-1c8a-4b0b-9b1c-d69867856cf7"
                )
                let step1: CodableORKStep = .init(
                    stepType: .getUpAndGo,
                    id: "Edmonton 11",
                    title: "",
                    text: ""
                )
//                let step2: CodableORKStep = .init(
//                    stepType: .sixMWT,
//                    id: "Second step",
//                    title: "Second step",
//                    text: "Second step"
//                )
                var firstSet: CodableORKSteps = .init()
                firstSet.codableORKSteps.append(step0)
                firstSet.codableORKSteps.append(step1)
                // firstSet.codableORKSteps.append(step2)
                stepsToInsert.dict.updateValue(firstSet, forKey: 13)
                let compStep: CodableORKStep = .init(
                    stepType: .completion,
                    id: "Completion step",
                    title: "Completion step",
                    text: "Completion step"
                )
                var secondSet: CodableORKSteps = .init()
                secondSet.codableORKSteps.append(compStep)
                stepsToInsert.dict.updateValue(secondSet, forKey: Int.max) // Int.max index forces the end of the array later on
                /// Set up the title overrides
                var overrides: CodableTitleMapDict = .init()
                overrides.dict.updateValue("Patient Questionnaire", forKey: "IntroStep")
                overrides.dict.updateValue("Draw a clock", forKey: "ClockStep")
                overrides.dict.updateValue("", forKey: "Edmonton 2")
                overrides.dict.updateValue("", forKey: "Edmonton 3")
                overrides.dict.updateValue("", forKey: "Edmonton 4")
                overrides.dict.updateValue("", forKey: "Edmonton 5")
                overrides.dict.updateValue("", forKey: "Edmonton 6")
                overrides.dict.updateValue("", forKey: "Edmonton 7")
                overrides.dict.updateValue("", forKey: "Edmonton 8")
                overrides.dict.updateValue("", forKey: "Edmonton 9")
                overrides.dict.updateValue("", forKey: "Edmonton 10")
                overrides.dict.updateValue("Get Up and Go", forKey: "GetUpAndGoIntro")
                overrides.dict.updateValue("How difficult was it for you to:", forKey: "WIQ 1")
                overrides.dict.updateValue("How difficult was it for you to:", forKey: "WIQ 2")
                overrides.dict.updateValue("How difficult was it for you to:", forKey: "WIQ 3")
                overrides.dict.updateValue("How difficult was it for you to:", forKey: "WIQ 4")
                overrides.dict.updateValue("How difficult was it for you to:", forKey: "WIQ 5")
                overrides.dict.updateValue("How difficult was it for you to:", forKey: "WIQ 6")
                overrides.dict.updateValue("How difficult was it for you to:", forKey: "WIQ 7")
                overrides.dict.updateValue("How difficult was it for you to:", forKey: "WIQ 8")
                overrides.dict.updateValue("How difficult was it for you to:", forKey: "WIQ 9")
                overrides.dict.updateValue("How difficult was it for you to:", forKey: "WIQ 10")
                overrides.dict.updateValue("How difficult was it for you to:", forKey: "WIQ 11")
                overrides.dict.updateValue("How difficult was it for you to:", forKey: "WIQ 12")
                overrides.dict.updateValue("How difficult was it for you to:", forKey: "WIQ 13")
                overrides.dict.updateValue("How difficult was it for you to:", forKey: "WIQ 14")
                overrides.dict.updateValue("", forKey: "VEINES 1")
                overrides.dict.updateValue("", forKey: "VEINES 2")
                overrides.dict.updateValue("", forKey: "VEINES 3")
                overrides.dict.updateValue("", forKey: "VEINES 4")
                overrides.dict.updateValue("", forKey: "VEINES 5")
                overrides.dict.updateValue("", forKey: "VEINES 6")
                overrides.dict.updateValue("", forKey: "VEINES 7")
                overrides.dict.updateValue("", forKey: "VEINES 8")

                let compQuestionnaire = CompoundQuestionnaire(
                    questionnaire: Bundle.main.questionnaire(
                        withName: "EdmontonWIQQuestionnaire-en-US"
                    ),
                    stepsToInsert: stepsToInsert,
                    titleOverrides: overrides
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
