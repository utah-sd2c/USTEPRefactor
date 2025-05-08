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

    private let compoundElements: CompoundQuestionnaireElement
    private let questionnaireResult: @MainActor (QuestionnaireResult) async -> Void
    private let cancelBehavior: CancelBehavior
    
    
    public var body: some View {
        if let task = createTask(compoundElements: compoundElements) {
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
        compoundElements: CompoundQuestionnaireElement,
        cancelBehavior: CancelBehavior = .shouldConfirmCancel,
        questionnaireResult: @escaping @MainActor (QuestionnaireResult) async -> Void
    ) {
        self.compoundElements = compoundElements
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
        stepsToInsert.updateValue([compStep], forKey: Questionnaire.dateTimeExample.item?.count ?? 0)
        return CompoundQuestionnaireView(
            compoundElements: CompoundQuestionnaireElement(
                questionnaire: .dateTimeExample,
                stepsToInsert: stepsToInsert
            )
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
    private func createTask(compoundElements: CompoundQuestionnaireElement) -> ORKNavigableOrderedTask? {
        // Create a navigable task from the Questionnaire and other steps
        do {
            var task: ORKNavigableOrderedTask = try ORKNavigableOrderedTask(questionnaire: compoundElements.questionnaire)
            // Insert additional steps into the Questionnaire
            if !compoundElements.stepsToInsert.keys.isEmpty {
                var keys = Array(compoundElements.stepsToInsert.keys).sorted(by: >)
                for key in keys {
                    var steps: [ORKStep] = compoundElements.stepsToInsert[key] ?? []
                    var len = steps.count
                    for ind in 0 ..< len {
                        var step: ORKStep = steps[ind]
                        task.insertStep(step, at: UInt(key + ind))
                    }
                }
            }
            return task
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
