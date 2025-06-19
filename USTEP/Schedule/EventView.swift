//
// This source file is part of the USTEP based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable closure_body_length
import ModelsR4
import SpeziQuestionnaire
import SpeziScheduler
import SwiftUI


struct EventView: View {
    private let event: Event

    @Environment(USTEPStandard.self) private var standard
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let compoundQuestionnaire = event.task.compoundQuestionnaire {
            CompoundQuestionnaireView(compoundQuestionnaire: compoundQuestionnaire) { result in
                
                dismiss()
                
                guard case let .completed(response) = result else {
                    return // user cancelled the task
                }
                
                event.complete()
                await standard.add(response: response)
                
                var edmontonScore = 0
                if let answers = response.item {
                    var score: Int = 0
                    for answer in answers {
                        if answer.linkId.value?.string != nil && answer.linkId.value!.string.starts(with: "Edmonton") {
                            if answer.answer != nil && !answer.answer!.isEmpty {
                                if let value = answer.answer![0].value {
                                    var answerScore: Int = 0
                                    if case let .coding(codingData) = value {
                                        if let codingScore: Int = Int(codingData.code?.value?.string ?? "0") {
                                            answerScore = codingScore
                                        }
                                    } else if case let .string(stringValue) = value {
                                        if let stringScore: Int = Int(stringValue.value?.string ?? "0") {
                                            answerScore = stringScore
                                        }
                                    } else {
                                        // No score present for this step
                                    }
                                    score += answerScore
                                }
                            }
                        }
                    }
                    edmontonScore = score
                }
                let healthCategories = ["Healthy", "Vulnerable", "Frail"]
                var category = healthCategories[0]
                if edmontonScore > 10 {
                    category = healthCategories[2]
                } else if edmontonScore > 5 {
                    category = healthCategories[1]
                }
            }
        } else {
            NavigationStack {
                ContentUnavailableView(
                    "Unsupported Event",
                    systemImage: "list.bullet.clipboard",
                    description: Text("This type of event is currently unsupported. Please contact the developer of this app.")
                )
                    .toolbar {
                        Button("Close") {
                            dismiss()
                        }
                    }
            }
        }
    }

    init(_ event: Event) {
        self.event = event
    }
}
