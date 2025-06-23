//
// This source file is part of the USTEP based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//
//
//import SpeziQuestionnaire
//import SpeziScheduler
//import SwiftUI
//
//
//struct EventView: View {
//    private let event: Event
//
//    @Environment(USTEPStandard.self) private var standard
//    @Environment(\.dismiss) private var dismiss
//
//    var body: some View {
//        if let compoundQuestionnaire = event.task.compoundQuestionnaire {
//            CompoundQuestionnaireView(compoundQuestionnaire: compoundQuestionnaire) { result in
//                dismiss()
//
//                guard case let .completed(response) = result else {
//                    return // user cancelled the task
//                }
//
//                event.complete()
//                await standard.add(response: response)
//            }
//        } else {
//            NavigationStack {
//                ContentUnavailableView(
//                    "Unsupported Event",
//                    systemImage: "list.bullet.clipboard",
//                    description: Text("This type of event is currently unsupported. Please contact the developer of this app.")
//                )
//                    .toolbar {
//                        Button("Close") {
//                            dismiss()
//                        }
//                    }
//            }
//        }
//    }
//
//    init(_ event: Event) {
//        self.event = event
//    }
//}
