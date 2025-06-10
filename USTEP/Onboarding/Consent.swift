//
// This source file is part of the USTEP based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziOnboarding
import SwiftUI


/// - Note: The `OnboardingConsentView` exports the signed consent form as PDF to the Spezi `Standard`, necessitating the conformance of the `Standard` to the `OnboardingConstraint`.
struct Consent: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    @State private var isDocumentLoaded = false
    @AppStorage("isSigningUp") private var isSigningUp = true
    
    private var consentDocument: Data {
        guard let path = Bundle.main.url(forResource: "ConsentDocument", withExtension: "md"),
              let data = try? Data(contentsOf: path) else {
            return Data(String(localized: "CONSENT_LOADING_ERROR").utf8)
        }
        // Sets the state here to enable the button
        DispatchQueue.main.async {
            isDocumentLoaded = true
        }
        return data
    }
    
    var body: some View {
        if !isSigningUp {
        Color.clear
            .task {
                onboardingNavigationPath.nextStep()
            }
    } else {
        ScrollViewReader { _ in
            OnboardingView(
                contentView: {
                    consentContent
                },
                actionView: {
                    consentActions
                }
            )
        }
    }
}
    private var consentContent: some View {
        VStack(spacing: 20) {
            logoImage
            HTMLView(
                asyncHTML: {
                    consentDocument
                }
            )
            Spacer(minLength: 0)
        }
    }
    
    private var logoImage: some View {
        Image("Uhealth_red")
            .resizable()
            .scaledToFill()
            .accessibilityLabel(Text("University of Utah logo"))
            .frame(width: 166, height: 44)
            .padding(.top, 10)
    }
    
    private var consentActions: some View {
        VStack(spacing: 16) {
            acceptButton
            Divider()
        }
        .padding(.horizontal)
        .padding(.top, 40)
    }
    
    private var acceptButton: some View {
        Button(action: {
            onboardingNavigationPath.append(UtahSignUp.self)
        }) {
            Text("I accept")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(16)
        }
        .disabled(!isDocumentLoaded)
    }
}
    
#if DEBUG
    #Preview {
        @Previewable @State var completed = false
        
        return OnboardingStack(onboardingFlowComplete: $completed) {
            Consent()
        }
        .previewWith(standard: USTEPStandard()) {
            OnboardingDataSource()
        }
    }
#endif
    
    

