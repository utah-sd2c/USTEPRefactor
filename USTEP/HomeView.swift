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
import SpeziAccount
import BackgroundTasks

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
    @StateObject private var healthKitManager = HealthKitManager()
    @AppStorage(StorageKeys.onboardingFlowComplete) private var completedOnboardingFlow = false
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Schedule", systemImage: "list.clipboard", value: .schedule) {
                ScheduleView(presentingAccount: $presentingAccount)
            }
            .customizationID("home.schedule")
            Tab("Trends", systemImage: "chart.line.uptrend.xyaxis", value: .trends) {
                Trends(presentingAccount: $presentingAccount)
            }
            .customizationID("home.trends")
            Tab("Profile", systemImage: "person.fill", value: .contact) {
                Contacts(presentingAccount: $presentingAccount)
            }
            .customizationID("home.contacts")
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabViewCustomization($tabViewCustomization)
        .sheet(isPresented: shouldShowSheet) {
            if !completedOnboardingFlow {
                OnboardingFlow()
            } else if presentingAccount {
                AccountSheet(dismissAfterSignIn: false)
            }
        }
        .onAppear {
            healthKitManager.configure(account: account)
            healthKitManager.startConfiguration()
            syncData()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                syncData()
            }
        }
        .onChange(of: selectedTab) { _ in
            syncData()
        }
    }
    
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
    
    private func syncData() {
        guard account.signedIn else { return }
        
        healthKitManager.enhancedSmartSync { success in
            DispatchQueue.main.async {
                if !success {
                    self.fallbackSync()
                }
            }
        }
    }
    
    @MainActor
    private func fallbackSync() {
        healthKitManager.stepCountCollectionExistsAndUpload { _ in }
        healthKitManager.distanceDataCollectionExistsAndUpload { _ in }
    }
}
#if DEBUG
#Preview {
    var details = AccountDetails()
    
    HomeView()
        .previewWith(standard: USTEPStandard()) {
            USTEPScheduler()
            AccountConfiguration(service: InMemoryAccountService(), activeDetails: details)
        }
}
#endif
