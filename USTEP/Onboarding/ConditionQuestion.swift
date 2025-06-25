//
// This source file is part of the CS342 2023 Utah Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//
// Condition Question from our old USTEP App
import SwiftUI
import SpeziOnboarding
import SpeziAccount
import SpeziFirebaseAccount
import FirebaseFirestore
import FirebaseAuth

struct ConditionQuestion: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    @Environment(Account.self) private var account
    @EnvironmentObject var firestoreManager: FirestoreManager
    
    @State private var selection = "Choose Diagnosis"
    var conditions = StorageKeys.conditions + ["Choose Diagnosis"]
    
    var body: some View {
        OnboardingView(
            contentView: {
                VStack {
                    OnboardingTitleView(
                        title: "What is your diagnosis?",
                        subtitle: "Please consult your doctor if you are unsure."
                    )
                    Spacer()
                    
                    Picker("Select your condition", selection: $selection) {
                        ForEach(conditions, id: \.self) { option in
                            Text(option).disabled(option == "Choose Diagnosis")
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemBackground))
                            .shadow(color: .gray, radius: 2)
                            .padding(.horizontal, 15)
                    )
                    .pickerStyle(.menu)
                    
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                }
            },
            actionView: {
                OnboardingActionsView(
                    primaryText: "Continue",
                    primaryAction: {
                        let defaults = UserDefaults.standard
                        defaults.set(selection, forKey: "disease")

                        Task {
                            guard let details = account.details else { return }
                            
                            do {
                                let userDocRef = Firestore.firestore().collection("users").document(details.accountId)
                                try await userDocRef.updateData(["disease": selection])
                                
                                await MainActor.run {
                                    firestoreManager.fetchAll()
                                    onboardingNavigationPath.nextStep()
                                }
                            } catch {
                                print("Error updating document: \(error)")
                            }
                        }
                    }
                )
                .disabled(selection == "Choose Diagnosis")
            }
        )
    }
}

#if DEBUG
#Preview{
    OnboardingStack {
        ConditionQuestion()
    }
        .environmentObject(FirestoreManager())
}
#endif
