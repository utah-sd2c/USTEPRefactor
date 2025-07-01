//
// This source file is part of the USTEP based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

@_spi(TestingSupport) import SpeziAccount
import SpeziAccount
import SpeziLicense
import SpeziOnboarding
import SwiftUI
import FirebaseAuth


// OLd way of Account sheet
//struct AccountSheet: View {
//    private let dismissAfterSignIn: Bool
//
//    @Environment(\.dismiss) var dismiss
//    
//    @Environment(Account.self) private var account
//    @Environment(\.accountRequired) var accountRequired
//    
//    @State var isInSetup = false
//    
//    
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                if account.signedIn && !isInSetup {
//                    AccountOverview(close: .showCloseButton) {
//                        NavigationLink {
//                            ContributionsList(projectLicense: .mit)
//                        } label: {
//                            Text("License Information")
//                        }
//                    }
//                } else {
//                    OnboardingStack{
//                        AccountSetup { _ in
//                            if dismissAfterSignIn {
//                                dismiss() // we just signed in, dismiss the account setup sheet
//                            }
//                        } header: {
//                            AccountSetupHeader()
//                        }
//                        .onAppear {
//                            isInSetup = true
//                        }
//                        .toolbar {
//                            if !accountRequired {
//                                closeButton
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//
//    @ToolbarContentBuilder private var closeButton: some ToolbarContent {
//        ToolbarItem(placement: .cancellationAction) {
//            Button("Close") {
//                dismiss()
//            }
//        }
//    }
//
//    init(dismissAfterSignIn: Bool = true) {
//        self.dismissAfterSignIn = dismissAfterSignIn
//    }
//}
//#if DEBUG
//#Preview("AccountSheet") {
//    var details = AccountDetails()
//    details.userId = "lelandstanford@stanford.edu"
//    details.name = PersonNameComponents(givenName: "Leland", familyName: "Stanford")
//
//    return AccountSheet()
//        .previewWith {
//            AccountConfiguration(service: InMemoryAccountService(), activeDetails: details)
//        }
//}

// New Account sheet to match our current logic where logout takes us back to Onboarding
struct AccountSheet: View {
    private let dismissAfterSignIn: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accountRequired) private var accountRequired
    @Environment(Account.self) private var account
    
    // Tracks onboarding completion state - when false, shows onboarding flow
    @AppStorage(StorageKeys.onboardingFlowComplete) private var completedOnboardingFlow = false
    
    var body: some View {
        NavigationStack {
            AccountOverview {
                AnyView(
                    NavigationLink {
                        ContributionsList(projectLicense: .mit)
                    } label: {
                        Text("License Information")
                    }
                )
            }
            .toolbar {
                if !accountRequired {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .onChange(of: account.signedIn) { oldValue, newValue in
            // When user signs out it dismisses this sheet and start the Onboarding flow
            if oldValue == true && newValue == false {
                // First dismiss, then reset after a delay
                dismiss()
                
                // Use a longer delay to ensure sheet is fully dismissed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    completedOnboardingFlow = false
                }
            }
        }
    }
    
    init(dismissAfterSignIn: Bool = true) {
        self.dismissAfterSignIn = dismissAfterSignIn
    }
}
#if DEBUG
#Preview("AccountSheet SignIn") {
    AccountSheet()
        .previewWith {
            AccountConfiguration(service: InMemoryAccountService())
        }
}
#endif
