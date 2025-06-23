//
// This source file is part of the USTEP based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//
//
// Old AccountSetupHeader code
//@_spi(TestingSupport) import SpeziAccount
//import SwiftUI
//
//
//struct AccountSetupHeader: View {
//    @Environment(Account.self) private var account
//    @Environment(\.accountSetupState) private var setupState
//    
//    
//    var body: some View {
//        VStack {
//            Text("Your Account")
//                .font(.largeTitle)
//                .bold()
//                .padding(.bottom)
//                .padding(.top, 30)
//            Text("ACCOUNT_SUBTITLE")
//                .padding(.bottom, 8)
//            if account.signedIn, case .presentingExistingAccount = setupState {
//                Text("ACCOUNT_SIGNED_IN_DESCRIPTION")
//            } else {
//                Text("ACCOUNT_SETUP_DESCRIPTION")
//            }
//        }
//            .multilineTextAlignment(.center)
//    }
//}
//
//
//#if DEBUG
//#Preview {
//    AccountSetupHeader()
//        .previewWith {
//            AccountConfiguration(service: InMemoryAccountService())
//        }
//}
//#endif

// New AccountSetupHeader to show us slides during Onboarding and decide what to show based of selection
//@_spi(TestingSupport) import SpeziAccount
//import SpeziFirebaseAccount
//import SwiftUI
//import FirebaseAuth
//import FirebaseFirestore
//import SpeziOnboarding
//
//struct AccountSetupHeader: View {
//    @Environment(Account.self) private var account
//    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
//    @AppStorage(StorageKeys.onboardingFlowComplete) private var completedOnboardingFlow = false
//    @AppStorage("isSigningUp") private var isSigningUp = true
//
//    @State private var hasProcessedSignIn = false
//
//    var body: some View {
//        VStack {
//            // Top Title Section
//            VStack(spacing: 8) {
//                Text("ACCOUNT_TITLE")
//                    .font(.largeTitle)
//                    .bold()
//            }
//            .padding(.top, 30)
//
//            Spacer(minLength: 20)
//
//            accountImage
//
//            accountDescription
//                .padding(.top, 30)
//
//            Spacer()
//
//            actionView
//        }
//        .padding()
//        .onAppear {
//            if account.signedIn && !hasProcessedSignIn {
//                hasProcessedSignIn = true
//                handleUserSignedIn()
//            }
//        }
//        .onChange(of: account.signedIn) { _, signedIn in
//            if signedIn && !hasProcessedSignIn {
//                hasProcessedSignIn = true
//                handleUserSignedIn()
//            }
//        }
//    }
//
//    @ViewBuilder
//    private var accountImage: some View {
//        Image(systemName: account.signedIn ? "person.badge.shield.checkmark.fill" : "person.fill.badge.plus")
//            .font(.system(size: 100))
//            .foregroundColor(.accentColor)
//            .padding(.top, 20)
//    }
//
//    @ViewBuilder
//    private var accountDescription: some View {
//        VStack(spacing: 12) {
//            if account.signedIn {
//                Text("ACCOUNT_SIGNED_IN_DESCRIPTION")
//                    .padding()
//            } else {
//                Text("ACCOUNT_SETUP_DESCRIPTION")
//            }
//        }
//        .padding(.vertical, 16)
//    }
//
//    @ViewBuilder
//    private var actionView: some View {
//        if account.signedIn {
//            OnboardingActionsView("ACCOUNT_NEXT") {
//                completedOnboardingFlow = true
//                onboardingNavigationPath.nextStep()
//            }
//        } else {
//            VStack(spacing: 20) {
//                Button {
//                    isSigningUp = true
//                    onboardingNavigationPath.append(Consent.self)
//                } label: {
//                    Text("Sign Up")
//                        .font(.headline)
//                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.accentColor)
//                        .cornerRadius(16)
//                }
//
//                Button {
//                    isSigningUp = false
//                    onboardingNavigationPath.append(UtahLogin.self)
//                } label: {
//                    Text("Login")
//                        .font(.headline)
//                        .foregroundColor(.accentColor)
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//
//    private func handleUserSignedIn() {
//        completedOnboardingFlow = true
//        onboardingNavigationPath.nextStep()
//
//        guard let user = Auth.auth().currentUser else {
//            print("No current user available.")
//            return
//        }
//
//        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
//            print("GoogleService-Info.plist not found. Skipping Firestore write.")
//            return
//        }
//
//        let fullName = user.displayName?.components(separatedBy: " ") ?? []
//        let firstName = fullName.first ?? ""
//        let lastName = fullName.dropFirst().joined(separator: " ")
//        let email = user.email ?? ""
//
//        let data: [String: Any] = [
//            "firstName": firstName,
//            "lastName": lastName,
//            "email": email,
//            "dateJoined": Timestamp()
//        ]
//
//        Firestore.firestore().collection("users").document(user.uid).setData(data) { error in
//            if let error = error {
//                print("Firestore write failed: \(error.localizedDescription)")
//            } else {
//                print("User document written to Firestore")
//            }
//        }
//    }
//}
//#if DEBUG
//#Preview("With OnboardingStack") {
//    OnboardingStack {
//        AccountSetupHeader() 
//    }
//    .previewWith {
//        OnboardingDataSource()
//        AccountConfiguration(service: InMemoryAccountService())
//    }
//}
//#endif
//@_spi(TestingSupport) import SpeziAccount
//import SpeziFirebaseAccount
//import SwiftUI
//import FirebaseAuth
//import FirebaseFirestore
//import SpeziOnboarding
//
//struct AccountSetupHeader: View {
//    @Environment(Account.self) private var account
//    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
//    @AppStorage(StorageKeys.onboardingFlowComplete) private var completedOnboardingFlow = false
//    @AppStorage("isSigningUp") private var isSigningUp = true
//
//    @State private var hasProcessedSignIn = false
//
//    var body: some View {
//        VStack {
//            // Top Title Section
//            VStack(spacing: 8) {
//                Text("ACCOUNT_TITLE")
//                    .font(.largeTitle)
//                    .bold()
//            }
//            .padding(.top, 30)
//
//            Spacer(minLength: 20)
//
//            accountImage
//
//            accountDescription
//                .padding(.top, 30)
//
//            Spacer()
//
//            actionView
//        }
//        .padding()
//        .onAppear {
//            if account.signedIn && !hasProcessedSignIn {
//                hasProcessedSignIn = true
//                handleUserSignedIn()
//            }
//        }
//        .onChange(of: account.signedIn) { _, signedIn in
//            if signedIn && !hasProcessedSignIn {
//                hasProcessedSignIn = true
//                handleUserSignedIn()
//            }
//        }
//    }
//
//    @ViewBuilder
//    private var accountImage: some View {
//        Image(systemName: account.signedIn ? "person.badge.shield.checkmark.fill" : "person.fill.badge.plus")
//            .font(.system(size: 100))
//            .foregroundColor(.accentColor)
//            .padding(.top, 20)
//    }
//
//    @ViewBuilder
//    private var accountDescription: some View {
//        VStack(spacing: 12) {
//            if account.signedIn {
//                Text("ACCOUNT_SIGNED_IN_DESCRIPTION")
//                    .padding()
//            } else {
//                Text("ACCOUNT_SETUP_DESCRIPTION")
//            }
//        }
//        .padding(.vertical, 16)
//    }
//
//    @ViewBuilder
//    private var actionView: some View {
//        if account.signedIn {
//            OnboardingActionsView("ACCOUNT_NEXT") {
//                completedOnboardingFlow = true
//                onboardingNavigationPath.nextStep()
//            }
//        } else {
//            VStack(spacing: 20) {
//                Button {
//                    isSigningUp = true
//                    onboardingNavigationPath.append(Consent.self)
//                } label: {
//                    Text("Sign Up")
//                        .font(.headline)
//                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.accentColor)
//                        .cornerRadius(16)
//                }
//
//                Button {
//                    isSigningUp = false
//                    onboardingNavigationPath.append(UtahLogin.self)
//                } label: {
//                    Text("Login")
//                        .font(.headline)
//                        .foregroundColor(.accentColor)
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//
//    private func handleUserSignedIn() {
//        completedOnboardingFlow = true
//        onboardingNavigationPath.nextStep()
//
//        guard let user = Auth.auth().currentUser else {
//            print("No current user available.")
//            return
//        }
//
//        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
//            print("GoogleService-Info.plist not found. Skipping Firestore write.")
//            return
//        }
//
//        let fullName = user.displayName?.components(separatedBy: " ") ?? []
//        let firstName = fullName.first ?? ""
//        let lastName = fullName.dropFirst().joined(separator: " ")
//        let email = user.email ?? ""
//
//        let data: [String: Any] = [
//            "firstName": firstName,
//            "lastName": lastName,
//            "email": email,
//            "dateJoined": Timestamp()
//        ]
//
//        // Direct Firestore access instead of using dependencies
//        Firestore.firestore().collection("users").document(user.uid).setData(data) { error in
//            if let error = error {
//                print("Firestore write failed: \(error.localizedDescription)")
//            } else {
//                print("User document written to Firestore")
//            }
//        }
//    }
//}
//
//#if DEBUG
//#Preview("With OnboardingStack") {
//    OnboardingStack {
//        AccountSetupHeader()
//    }
//    .previewWith {
//        OnboardingDataSource()
//        AccountConfiguration(service: InMemoryAccountService())
//    }
//}
//#endif
@_spi(TestingSupport) import SpeziAccount
import SpeziFirebaseAccount
import SwiftUI
import SpeziOnboarding

struct AccountSetupHeader: View {
    @Environment(Account.self) private var account
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    @AppStorage(StorageKeys.onboardingFlowComplete) private var completedOnboardingFlow = false
    @AppStorage("isSigningUp") private var isSigningUp = true

    var body: some View {
        VStack {
            // Top Title Section
            VStack(spacing: 8) {
                Text("ACCOUNT_TITLE")
                    .font(.largeTitle)
                    .bold()
            }
            .padding(.top, 30)

            Spacer(minLength: 20)

            accountImage

            accountDescription
                .padding(.top, 30)

            Spacer()

            actionView
        }
        .padding()
        .onChange(of: account.signedIn) { _, signedIn in
            if signedIn {
                // User has signed in - just complete onboarding and move to next step
                completedOnboardingFlow = true
                onboardingNavigationPath.nextStep()
            }
        }
    }

    @ViewBuilder
    private var accountImage: some View {
        Image(systemName: account.signedIn ? "person.badge.shield.checkmark.fill" : "person.fill.badge.plus")
            .font(.system(size: 100))
            .foregroundColor(.accentColor)
            .padding(.top, 20)
    }

    @ViewBuilder
    private var accountDescription: some View {
        VStack(spacing: 12) {
            if account.signedIn {
                Text("ACCOUNT_SIGNED_IN_DESCRIPTION")
                    .padding()
            } else {
                Text("ACCOUNT_SETUP_DESCRIPTION")
            }
        }
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private var actionView: some View {
        if account.signedIn {
            OnboardingActionsView("ACCOUNT_NEXT") {
                completedOnboardingFlow = true
                onboardingNavigationPath.nextStep()
            }
        } else {
            VStack(spacing: 20) {
                Button {
                    isSigningUp = true
                    onboardingNavigationPath.append(Consent.self)
                } label: {
                    Text("Sign Up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(16)
                }

                Button {
                    isSigningUp = false
                    onboardingNavigationPath.append(UtahLogin.self)
                } label: {
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
        }
    }
}

#if DEBUG
#Preview("With OnboardingStack") {
    OnboardingStack {
        AccountSetupHeader()
    }
    .previewWith {
        OnboardingDataSource()
        AccountConfiguration(service: InMemoryAccountService())
    }
}
#endif
