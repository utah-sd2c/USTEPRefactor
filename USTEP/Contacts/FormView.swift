//
// This source file is part of the CS342 2023 Utah Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

// FormView from our old USTEP App
import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import SpeziAccount

struct FormView: View {
    @Environment(Account.self) private var account
    @EnvironmentObject var firestoreManager: FirestoreManager
    @Binding var disease: String
    @Binding var isEditing: Bool
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Diagnosis")) {
                    Picker("Change your diagnosis", selection: $disease) {
                        ForEach(StorageKeys.conditions, id: \.self) { option in
                            Text(option)
                        }
                    }
                    .padding(.vertical, 10)
                }
                
                Button(action: {
                    saveDisease()
                }) {
                    HStack {
                        Spacer()
                        Text("Save")
                        Spacer()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isEditing = false
                    }
                }
            }
        }
    }
    
    private func saveDisease() {
        // Stores condition locally in UserDefaults
        let defaults = UserDefaults.standard
        defaults.set(disease, forKey: "disease")

        Task {
            guard let details = account.details else { return }
            
            do {
                let userDocRef = Firestore.firestore().collection("users").document(details.accountId)
                try await userDocRef.updateData(["disease": disease])
                
                // Updates FirestoreManager
                await MainActor.run {
                    firestoreManager.fetchAll()
                    isEditing = false
                }
            } catch {
                print("Error updating document: \(error)")
            }
        }
    }
}
