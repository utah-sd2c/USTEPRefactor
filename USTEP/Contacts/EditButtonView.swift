//
// This source file is part of the CS342 2023 Utah Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

// Edit Button from our old USTEP App
import SwiftUI
import SpeziOnboarding
import SpeziAccount

struct EditButton: View {
    @Environment(Account.self) private var account
    @State private var isEditing = false
    @EnvironmentObject var firestoreManager: FirestoreManager

    var body: some View {
        HStack {
            Button(action: {
                isEditing = true
            }, label: {
                Text("Edit")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 20))
                    .fontWeight(.medium)
            })
            Spacer()
                .sheet(isPresented: $isEditing) {
                    FormView(disease: $firestoreManager.disease, isEditing: $isEditing)
                                        .environmentObject(firestoreManager)
                }
        }
    }
}
   
