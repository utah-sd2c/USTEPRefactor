//
// This source file is part of the USTEP based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

// Helper SwiftUI component that creates a standardized action button layout for onboarding screens.(used in AccountSetupHeader)
import SwiftUI

struct OnboardingActionsView: View {
    let primaryText: String
    let primaryAction: () -> Void
    var secondaryText: String?
    var secondaryAction: (() -> Void)? = nil

    init(
        _ primaryText: String,
        action: @escaping () -> Void
    ) {
        self.primaryText = primaryText
        self.primaryAction = action
    }

    init(
        primaryText: String,
        primaryAction: @escaping () -> Void,
        secondaryText: String? = nil,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.primaryText = primaryText
        self.primaryAction = primaryAction
        self.secondaryText = secondaryText
        self.secondaryAction = secondaryAction
    }

    var body: some View {
        VStack(spacing: 12) {
            Button(action: primaryAction) {
                Text(primaryText)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            if let secondaryText, let secondaryAction {
                Button(action: secondaryAction) {
                    Text(secondaryText)
                        .foregroundColor(.accentColor)
                        .underline()
                }
            }
        }
        .padding(.horizontal)
    }
}
