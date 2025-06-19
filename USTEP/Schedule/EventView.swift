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


// Define a struct for your Frailty outcome (as you had in comments, but make it Codable/Hashable if needed elsewhere)
struct FrailtyOutcome: Identifiable, Hashable, Codable {
    var id = UUID() // Essential for Identifiable
    let score: Int
    let category: String
}

struct EventView: View {
    private let event: Event // The event triggering this questionnaire

    @Environment(USTEPStandard.self) private var standard // Assuming this is set up correctly
    @Environment(\.dismiss) private var dismiss // To dismiss the EventView itself

    // State to control the presentation of the summary sheet
    @State private var frailtyOutcome: FrailtyOutcome?
    @State private var showSummarySheet = false

    var body: some View {
        if let compoundQuestionnaire = event.task.compoundQuestionnaire {
            CompoundQuestionnaireView(compoundQuestionnaire: compoundQuestionnaire) { result in
                // This closure runs AFTER the questionnaire finishes
                
                // Always dismiss the questionnaire itself first (if it's a modal)
                // If EventView is itself presented modally (e.g., as a sheet),
                // uncommenting this dismiss() will dismiss EventView,
                // and then you'll present the summary from wherever EventView was called.
                // For now, let's assume EventView is embedded and we want to show a sheet on top.
                // dismiss() // Uncomment if EventView itself is a sheet/fullScreenCover that should disappear
                
                guard case let .completed(response) = result else {
                    // User cancelled, just dismiss the EventView or handle as appropriate
                    dismiss() // Dismiss the current EventView if task was cancelled
                    return
                }
                
                // Mark the event as complete in your scheduler
                event.complete()
                
            
                await standard.add(response: response)
                
                // Process questionnaire results to calculate score
                var edmontonScore = 0
                if let answers = response.item {
                    for answer in answers {
                        // Check if linkId is not nil and starts with "Edmonton"
                        if let linkIdString = answer.linkId.value?.string,
                           linkIdString.starts(with: "Edmonton"),
                           let firstAnswer = answer.answer?.first, // Get the first answer if it exists
                           let value = firstAnswer.value {
                            
                            var answerScore: Int? = nil // Use optional for safer parsing

                            switch value {
                            case let .coding(codingData):
                                answerScore = Int(codingData.code?.value?.string ?? "")
                            case let .string(stringValue):
                                answerScore = Int(stringValue.value?.string ?? "")
                            default:
                                // Handle other value types if necessary, or just ignore
                                break
                            }
                            
                            if let scoreToAdd = answerScore {
                                edmontonScore += scoreToAdd
                            }
                        }
                    }
                }
                
                // Determine category based on score
                let healthCategories = ["Healthy", "Vulnerable", "Frail"]
                var category = healthCategories[0]
                if edmontonScore > 10 {
                    category = healthCategories[2]
                } else if edmontonScore > 5 {
                    category = healthCategories[1]
                }
                
                // Create the outcome and trigger the summary sheet
                self.frailtyOutcome = FrailtyOutcome(score: edmontonScore, category: category)
                self.showSummarySheet = true // Trigger presentation of the sheet
            }
            // This is where the summary sheet is presented
            .sheet(isPresented: $showSummarySheet) {
                // When the sheet is dismissed, also dismiss the EventView
                FrailtyView(frailty: frailtyOutcome ?? FrailtyOutcome(score: 0, category: "Unknown"))
                    .interactiveDismissDisabled() // Prevent swipe to dismiss if you want
                    .onDisappear {
                        // After the summary sheet is dismissed, dismiss the EventView
                        // This ensures the questionnaire is fully gone before returning to your app's main flow.
                        dismiss()
                    }
            }
        } else {
            // This else block handles the case where event.task.compoundQuestionnaire is nil
            // This part of your code was generally fine, just ensure it's in a proper NavigationStack
            // if it's meant to be pushed, or presented modally.
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

    // Your initializer
    init(_ event: Event) {
        self.event = event
    }
}

// Your FrailtyView, now a standalone View struct
struct FrailtyView: View {
    let frailty: FrailtyOutcome
    
    // You'll need dismiss here too, to close the sheet itself
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack { // Wrap in NavigationStack if you want nav bar title/buttons
            VStack {
                Spacer()
                Text("Frailty Score")
                    .font(.largeTitle)
                    .padding(.bottom, 5)
                Text("Score: \(frailty.score) (\(frailty.category))")
                    .font(.title2)
                Spacer()
                Button("Close") {
                    dismiss() // This dismisses the FrailtyView sheet
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
            }
            .navigationTitle("Summary") // Set navigation title for the sheet
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
