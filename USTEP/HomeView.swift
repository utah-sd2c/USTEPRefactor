//
// This source file is part of the USTEP based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

//@_spi(TestingSupport) import SpeziAccount
//import SwiftUI
//import SpeziOnboarding
//import SpeziFirebaseAccount
//import SpeziViews

//struct HomeView: View {
//    enum Tabs: String {
//        case schedule
//        case trends
//        case contact
//    }
//
//
//    @AppStorage(StorageKeys.homeTabSelection) private var selectedTab = Tabs.schedule
//    @AppStorage(StorageKeys.tabViewCustomization) private var tabViewCustomization = TabViewCustomization()
//
//    @State private var presentingAccount = false
//
//    
//    var body: some View {
//        TabView(selection: $selectedTab) {
//            Tab("Schedule", systemImage: "list.clipboard", value: .schedule) {
//                ScheduleView(presentingAccount: $presentingAccount)
//            }
//                .customizationID("home.schedule")
//            Tab("Trends", systemImage: "chart.line.uptrend.xyaxis", value: .trends) {
//            }
//                .customizationID("home.trends")
//            Tab("Profile", systemImage: "person.fill", value: .contact) {
//                Contacts(presentingAccount: $presentingAccount)
//            }
//                .customizationID("home.contacts")
//        }
//            .tabViewStyle(.sidebarAdaptable)
//            .tabViewCustomization($tabViewCustomization)
//            .sheet(isPresented: $presentingAccount) {
//                AccountSheet(dismissAfterSignIn: false) // presentation was user initiated, do not automatically dismiss
//            }
//            .accountRequired(!FeatureFlags.disableFirebase && !FeatureFlags.skipOnboarding) {
//                AccountSheet()
//            }
//    }
//}

// New HomeView based of our last USTEP App
@_spi(TestingSupport) import SpeziAccount
import SwiftUI
import SpeziOnboarding
import SpeziFirebaseAccount
import SpeziViews

struct HomeView: View {
    enum Tabs: String {
        case schedule
        case trends
        case contact
    }
    
    
    @AppStorage(StorageKeys.homeTabSelection) private var selectedTab = Tabs.schedule
    @AppStorage(StorageKeys.tabViewCustomization) private var tabViewCustomization = TabViewCustomization()
    
    @State private var presentingAccount = false
    @Environment(Account.self) private var account
    @AppStorage(StorageKeys.onboardingFlowComplete) private var completedOnboardingFlow = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Schedule", systemImage: "list.clipboard", value: .schedule) {
                ScheduleView(presentingAccount: $presentingAccount)
            }
            .customizationID("home.schedule")
            Tab("Trends", systemImage: "chart.line.uptrend.xyaxis", value: .trends) {
            }
            .customizationID("home.trends")
            Tab("Profile", systemImage: "person.fill", value: .contact) {
                Contacts(presentingAccount: $presentingAccount)
            }
            .customizationID("home.contacts")
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabViewCustomization($tabViewCustomization)
        // Single sheet that shows either onboarding or account based on state
        .sheet(isPresented: shouldShowSheet) {
            if !completedOnboardingFlow {
                OnboardingFlow()
            } else if presentingAccount {
                AccountSheet(dismissAfterSignIn: false)
            }
        }
    }
    
    // Add this computed property to show sheets
    private var shouldShowSheet: Binding<Bool> {
        Binding(
            get: {
                !completedOnboardingFlow || presentingAccount
            },
            set: { newValue in
                if !newValue && completedOnboardingFlow {
                    presentingAccount = false
                }
            }
        )
    }
    
    private var shouldPresentAccountSheet: Binding<Bool> {
        Binding(
            get: { presentingAccount && completedOnboardingFlow },
            set: { presentingAccount = $0 }
        )
    }
}
#if DEBUG
#Preview {
    var details = AccountDetails()
    
    return HomeView()
        .previewWith(standard: USTEPStandard()) {
            USTEPScheduler()
            AccountConfiguration(service: InMemoryAccountService(), activeDetails: details)
        }
}
#endif
