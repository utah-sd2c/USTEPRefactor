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
