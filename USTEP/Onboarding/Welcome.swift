//
// This source file is part of the USTEP based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziOnboarding
import SwiftUI


struct Welcome: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    
    
    var body: some View {
        Image("Uhealth_red")
            .resizable()
            .scaledToFill()
            .accessibilityLabel(Text("University of Utah logo"))
            .frame(width: 166, height: 44)
            .padding(.top, 40)

        OnboardingView(
            title: "USTEP",
            subtitle: "WELCOME_SUBTITLE",
            areas: [
                OnboardingInformationView.Content(
                    icon: {
                        Image(systemName: "list.clipboard")
                            .accessibilityHidden(true)
                    },
                    title: "Report your health outcomes",
                    description: "WELCOME_AREA1_DESCRIPTION"
                ),
                OnboardingInformationView.Content(
                    icon: {
                        Image(systemName: "figure.walk")
                            .accessibilityHidden(true)
                    },
                    title: "Track your health",
                    description: "WELCOME_AREA2_DESCRIPTION"
                ),
                OnboardingInformationView.Content(
                    icon: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .accessibilityHidden(true)
                    },
                    title: "Monitor your progress",
                    description: "WELCOME_AREA3_DESCRIPTION"
                )
            ],
            actionText: "Next",
            action: {
                onboardingNavigationPath.nextStep()
            }
        )
            .padding(.top, 24)
    }
}


#if DEBUG
#Preview {
    OnboardingStack {
        Welcome()
    }
}
#endif
