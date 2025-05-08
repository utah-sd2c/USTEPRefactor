//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import FHIRQuestionnaires
import ModelsR4
import OSLog
import ResearchKit
import ResearchKitOnFHIR
import ResearchKitSwiftUI
import SpeziQuestionnaire
import SwiftUI


/// Present a FHIR `Questionnaire` and additional steps  to the user.
/// See the makeTestView function for an example of how to use this struct
public struct CompoundQuestionnaireView: View {
    private static let logger = Logger(subsystem: "edu.stanford.spezi.questionnaire", category: "CompoundQuestionnaireView")

    private let compoundQuestionnaire: CompoundQuestionnaire?
    private let questionnaireResult: @MainActor (QuestionnaireResult) async -> Void
    private let cancelBehavior: CancelBehavior
    
    
    public var body: some View {
        if let task = createTask(compoundQuestionnaire: compoundQuestionnaire) {
            ORKOrderedTaskView(tasks: task, tintColor: .accentColor, cancelBehavior: cancelBehavior, result: handleResult)
                .ignoresSafeArea(.container, edges: .bottom)
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .interactiveDismissDisabled()
        } else {
            Text("QUESTIONNAIRE_LOADING_ERROR_MESSAGE")
        }
    }
    
    
    /// - Parameters:
    ///   - compoundElements: The questionnaire and additional steps to display
    ///   - cancelBehavior: The cancel behavior of view. The default setting allows cancellation and asks for confirmation before the view is dismissed.
    ///   - questionnaireResult: Result closure that processes the ``QuestionnaireResult``.
    public init(
        compoundQuestionnaire: CompoundQuestionnaire?,
        cancelBehavior: CancelBehavior = .shouldConfirmCancel,
        questionnaireResult: @escaping @MainActor (QuestionnaireResult) async -> Void
    ) {
        self.compoundQuestionnaire = compoundQuestionnaire
        self.cancelBehavior = cancelBehavior
        self.questionnaireResult = questionnaireResult
    }
    
#if DEBUG
    public static func makeTestView() -> CompoundQuestionnaireView {
        var stepsToInsert: [Int: [ORKStep]] = [:]
        var step0: ORKStep
        step0 = ORKInstructionStep(identifier: "First step")
        step0.text = "First step"
        var step1: ORKStep
        step1 = ORKInstructionStep(identifier: "Second step")
        step1.text = "Second step"
        stepsToInsert.updateValue([step0, step1], forKey: 1)
        var compStep: ORKStep
        compStep = ORKCompletionStep(identifier: "Completion step")
        compStep.text = "Completion step"
        stepsToInsert.updateValue([compStep], forKey: -1) // -1 index forces the end of the array later on
        let compQuestionnaire = CompoundQuestionnaire(
            questionnaire: Questionnaire.dateTimeExample,
            stepsToInsert: stepsToInsert
        )
        return CompoundQuestionnaireView(
            compoundQuestionnaire: compQuestionnaire
        ) { response in
            print("Received response \(response)")
        }
    }
#endif
    
    private func handleResult(_ result: TaskResult) async {
        let questionnaireResult: QuestionnaireResult
        switch result {
        case let .completed(result):
            questionnaireResult = .completed(result.fhirResponse)
        case .cancelled:
            questionnaireResult = .cancelled
        case .failed:
            questionnaireResult = .failed
        }

        await self.questionnaireResult(questionnaireResult)
    }

    
    /// Creates a ResearchKit navigable task from a questionnaire
    /// - Parameter compoundElements: a questionnaire and optional list of steps to add
    /// - Returns: a ResearchKit navigable task
    private func createTask(compoundQuestionnaire: CompoundQuestionnaire?) -> ORKNavigableOrderedTask? {
        // Create a navigable task from the Questionnaire and other steps
        do {
            if let compQuestionnaire: CompoundQuestionnaire = compoundQuestionnaire {
                let task: ORKNavigableOrderedTask = try ORKNavigableOrderedTask(questionnaire: compQuestionnaire)
                // Insert additional steps into the Questionnaire
                let stepsToInsert = compQuestionnaire.stepsToInsert
                if !stepsToInsert.keys.isEmpty {
                    let keys = Array(stepsToInsert.keys).sorted(by: >)
                    for key in keys {
                        var questionnaireIndex = key
                        if key < 0 || key > compQuestionnaire.item?.count ?? 0 {
                            questionnaireIndex = compQuestionnaire.item?.count ?? 0
                        }
                        let steps: [ORKStep] = stepsToInsert[questionnaireIndex] ?? []
                        let len = steps.count
                        for ind in 0 ..< len {
                            let step: ORKStep = steps[ind]
                            task.insertStep(step, at: UInt(key + ind))
                        }
                    }
                }
                return task
            }
            return nil
        } catch {
            Self.logger.error("Failed to create ORK task: \(error)")
            return nil
        }
    }
}


#if DEBUG
#Preview {
    CompoundQuestionnaireView.makeTestView()
}
#endif
