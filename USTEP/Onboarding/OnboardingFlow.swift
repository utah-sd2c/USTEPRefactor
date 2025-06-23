//
// This source file is part of the USTEP based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//
//
//@_spi(TestingSupport) import SpeziAccount
//import SpeziFirebaseAccount
//import SpeziHealthKit
//import SpeziNotifications
//import SpeziOnboarding
//import SwiftUI


// Displays an multi-step onboarding flow for the USTEP.
//struct OnboardingFlow: View {
//    @Environment(HealthKit.self) private var healthKit
//    
//    @Environment(\.scenePhase) private var scenePhase
//    @Environment(\.notificationSettings) private var notificationSettings
//    
//    @AppStorage(StorageKeys.onboardingFlowComplete) private var completedOnboardingFlow = false
//    
//    @State private var localNotificationAuthorization = false
//    
//    
//
//    @MainActor private var healthKitAuthorization: Bool {
//        // As HealthKit not available in preview simulator
//        if ProcessInfo.processInfo.isPreviewSimulator {
//            return false
//        }
//        return healthKit.isFullyAuthorized
//    }
//    
////    
//        var body: some View {
//            OnboardingStack(onboardingFlowComplete: $completedOnboardingFlow) {
//                Welcome()
//    //            InterestingModules()
//                AccountSetupHeader()
//                
//#if !(targetEnvironment(simulator) && (arch(i386) || arch(x86_64)))
//    Consent()
//#endif
//
//    UtahSignUp()
//                UtahLogin()
//                if !FeatureFlags.disableFirebase {
//                    AccountOnboarding()
//                }
//    
//                if HKHealthStore.isHealthDataAvailable() && !healthKitAuthorization {
//                    HealthKitPermissions()
//                }
//    
//                if !localNotificationAuthorization {
//                    NotificationPermissions()
//                }
//            }
//                .interactiveDismissDisabled(!completedOnboardingFlow)
//                .onChange(of: scenePhase, initial: true) {
//                    guard case .active = scenePhase else {
//                        return
//                    }
//    
//                    Task {
//                        localNotificationAuthorization = await notificationSettings().authorizationStatus == .authorized
//                    }
//                }
//        }
//    }

// Displays an multi-step onboarding flow for the USTEP.
@_spi(TestingSupport) import SpeziAccount
import SpeziFirebaseAccount
import SpeziHealthKit
import SpeziNotifications
import SpeziOnboarding
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct OnboardingFlow: View {
    @Environment(HealthKit.self) private var healthKit
    @Environment(Account.self) private var account
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.notificationSettings) private var notificationSettings
    
    @AppStorage(StorageKeys.onboardingFlowComplete) private var completedOnboardingFlow = false
    @AppStorage("isSigningUp") private var isSigningUp = true
    @State private var localNotificationAuthorization = false
    @State private var healthKitAuthorizationStatus = false
    
    var body: some View {
        OnboardingStack(onboardingFlowComplete: $completedOnboardingFlow) {
            Welcome()
            AccountSetupHeader()
            
            // Our logic will decide which view to show
            Consent()
            UtahSignUp()
            UtahLogin()
            
            if !FeatureFlags.disableFirebase {
                AccountOnboarding()
            }
            
            if HKHealthStore.isHealthDataAvailable() && !healthKitAuthorizationStatus {
                HealthKitPermissions()
            }
            
            if !localNotificationAuthorization {
                NotificationPermissions()
            }
        }
        
        .interactiveDismissDisabled(!completedOnboardingFlow)
        .task {
            await updateHealthKitStatus()
        }
        .onChange(of: scenePhase, initial: true) {
            guard case .active = scenePhase else { return }
            
            Task {
                localNotificationAuthorization = await notificationSettings().authorizationStatus == .authorized
                
                await updateHealthKitStatus()
                
                await MainActor.run {
                    if account.signedIn && localNotificationAuthorization && healthKitAuthorizationStatus && !completedOnboardingFlow {
                        completedOnboardingFlow = true
                    }
                }
                
            }
        }
        // Adding this to complete onboarding when conditions are met
        .onChange(of: localNotificationAuthorization) { _, authorized in
            if account.signedIn && authorized && healthKitAuthorizationStatus && !completedOnboardingFlow {
                completedOnboardingFlow = true
            }
        }
        .onChange(of: account.signedIn) { _, signedIn in
            if signedIn {
                print("🚀 User signed in, checking if user document exists...")
                
                // Try Spezi Account first
                if let details = account.details {
                    let userDocRef = Firestore.firestore().collection("users").document(details.accountId)
                    
                    // Check if document already exists
                    userDocRef.getDocument { document, error in
                        if let error = error {
                            print("❌ Error checking user document: \(error)")
                            return
                        }
                        
                        if let document = document, document.exists {
                            print("ℹ️ User document already exists, skipping creation")
                            return
                        }
                        
                        // Document doesn't exist, create it
                        print("📝 Creating new user document...")
                        let userData: [String: Any] = [
                            "firstName": details.name?.givenName ?? "",
                            "lastName": details.name?.familyName ?? "",
                            "email": details.email ?? "",
                            "dateJoined": Timestamp(date: Date())
                        ]
                        
                        userDocRef.setData(userData) { error in
                            if let error = error {
                                print("❌ User document creation failed: \(error)")
                            } else {
                                print("✅ User document created successfully!")
                            }
                        }
                    }
                } else if let user = Auth.auth().currentUser {
                    // Fallback to Firebase Auth
                    let userDocRef = Firestore.firestore().collection("users").document(user.uid)
                    
                    // Check if document already exists
                    userDocRef.getDocument { document, error in
                        if let error = error {
                            print("❌ Error checking Firebase user document: \(error)")
                            return
                        }
                        
                        if let document = document, document.exists {
                            print("ℹ️ Firebase user document already exists, skipping creation")
                            return
                        }
                        
                        // Document doesn't exist, create it
                        print("📝 Creating new Firebase user document...")
                        let fullName = user.displayName?.components(separatedBy: " ") ?? []
                        let userData: [String: Any] = [
                            "firstName": fullName.first ?? "",
                            "lastName": fullName.dropFirst().joined(separator: " "),
                            "email": user.email ?? "",
                            "dateJoined": Timestamp(date: Date())
                        ]
                        
                        userDocRef.setData(userData) { error in
                            if let error = error {
                                print("❌ Firebase user document creation failed: \(error)")
                            } else {
                                print("✅ Firebase user document created successfully!")
                            }
                        }
                    }
                }
            }
        }
    }
    
    @MainActor
    private func updateHealthKitStatus() async {
        if ProcessInfo.processInfo.isPreviewSimulator {
            healthKitAuthorizationStatus = false
        } else {
            healthKitAuthorizationStatus = healthKit.isFullyAuthorized
        }
    }
}

#if DEBUG
#Preview {
    OnboardingFlow()
        .previewWith(standard: USTEPStandard()) {
            OnboardingDataSource()
            HealthKit()
            AccountConfiguration(service: InMemoryAccountService())
            USTEPScheduler()
        }
}
#endif
