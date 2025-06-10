//
// This source file is part of the CS342 2023 Utah Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

// Logout button from our Old USTEP App
import FirebaseAuth
import SpeziAccount
import SwiftUI
import SpeziOnboarding


struct LogoutButton: View {
    @Binding var eventBool: Bool
    @Environment(\.dismiss) private var dismiss

    @AppStorage(StorageKeys.onboardingFlowComplete)
    private var completedOnboardingFlow = true

    @Environment(Account.self)
    private var account
    
    var buttonLabel: String
    var foregroundColor: Color
    var backgroundColor: Color
    
    var body: some View {
        Button(action: {
            Task {
                do {
                    try await account.accountService.logout()
                    
                    await MainActor.run {
                        eventBool = true
                        completedOnboardingFlow = false
                    }
                    
                    print("Successfully signed out via SpeziAccount service")
                } catch {
                    print("Error signing out: \(error.localizedDescription)")
                }
            }
        }) {
            Text(buttonLabel)
                .padding()
                .frame(maxWidth: .infinity)
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .cornerRadius(10)
        }
        .padding(.bottom, 30)
    }
}
