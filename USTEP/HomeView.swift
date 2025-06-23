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

//struct HomeView: View {
//    enum Tabs: String {
//        case schedule
//        case trends
//        case contact
//    }
//    
//    @AppStorage(StorageKeys.homeTabSelection) private var selectedTab = Tabs.schedule
//    @AppStorage(StorageKeys.tabViewCustomization) private var tabViewCustomization = TabViewCustomization()
//    @StateObject private var healthKitManager = HealthKitManager()
//    @State private var presentingAccount = false
//    @Environment(Account.self) private var account
//    @AppStorage(StorageKeys.onboardingFlowComplete) private var completedOnboardingFlow = false
//    @Environment(\.scenePhase) var scenePhase
//    
//    // We'll get these dependencies in onAppear instead of using @Dependency
//    @State private var firebaseConfig: FirebaseConfiguration?
//    @State private var accountService: FirebaseAccountService?
//    
//    var body: some View {
//        TabView(selection: $selectedTab) {
//            Tab("Schedule", systemImage: "list.clipboard", value: .schedule) {
//                ScheduleView(presentingAccount: $presentingAccount)
//            }
//            .customizationID("home.schedule")
//            Tab("Trends", systemImage: "chart.line.uptrend.xyaxis", value: .trends) {
//                Trends(presentingAccount: $presentingAccount)
//            }
//            .customizationID("home.trends")
//            Tab("Profile", systemImage: "person.fill", value: .contact) {
//                Contacts(presentingAccount: $presentingAccount)
//            }
//            .customizationID("home.contacts")
//        }
//        .tabViewStyle(.sidebarAdaptable)
//        .tabViewCustomization($tabViewCustomization)
//        .sheet(isPresented: shouldShowSheet) {
//            if !completedOnboardingFlow {
//                OnboardingFlow()
//            } else if presentingAccount {
//                AccountSheet(dismissAfterSignIn: false)
//            }
//        }
//        .onAppear {
//            // Get dependencies from Spezi when view appears
//            Task {
//                await configureDependencies()
//                healthKitManager.startConfiguration()
//                syncData()
//            }
//        }
//        .onChange(of: scenePhase) { newPhase in
//            if newPhase == .active {
//                syncData()
//            }
//        }
//        .onChange(of: selectedTab) { _ in
//            syncData()
//        }
//        .environmentObject(healthKitManager) // Make it available to child views
//    }
//    
//    private func configureDependencies() async {
//        // For now, create FirebaseConfiguration directly
//        // This avoids the Spezi dependency resolution issue
//        let firebaseConfig = FirebaseConfiguration()
//        firebaseConfig.configure(account: account, accountService: nil)
//        
//        self.firebaseConfig = firebaseConfig
//        healthKitManager.configure(account: account, config: firebaseConfig)
//    }
//    
//    // Fixed: Single shouldShowSheet computed property (removed duplicate)
//    private var shouldShowSheet: Binding<Bool> {
//        Binding(
//            get: {
//                !completedOnboardingFlow || presentingAccount
//            },
//            set: { newValue in
//                if !newValue && completedOnboardingFlow {
//                    presentingAccount = false
//                }
//            }
//        )
//    }
//    
//    private func syncData() {
//        // Your existing sync logic here
//        healthKitManager.stepCountCollectionExistsAndUpload { success in
//            if success {
//                print("Step data synced successfully")
//            }
//        }
//        
//        healthKitManager.distanceDataCollectionExistsAndUpload { success in
//            if success {
//                print("Distance data synced successfully")
//            }
//        }
//    }
//}
struct HomeView: View {
    enum Tabs: String {
        case schedule
        case trends
        case contact
    }
    
    @AppStorage(StorageKeys.homeTabSelection) private var selectedTab = Tabs.schedule
    @AppStorage(StorageKeys.tabViewCustomization) private var tabViewCustomization = TabViewCustomization()
    @StateObject private var healthKitManager = HealthKitManager()
    @State private var presentingAccount = false
    @Environment(Account.self) private var account
    @AppStorage(StorageKeys.onboardingFlowComplete) private var completedOnboardingFlow = false
    @Environment(\.scenePhase) var scenePhase
    
    // We'll get these dependencies in onAppear instead of using @Dependency
    @State private var firebaseConfig: FirebaseConfiguration?
    @State private var accountService: FirebaseAccountService?
    
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
            Task {
                await configureDependencies()
                healthKitManager.startConfiguration()
                await waitAndSync()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                syncData()
            }
        }
        .onChange(of: selectedTab) { _ in
            syncData()
        }
        .environmentObject(healthKitManager)
    }
    
    private func configureDependencies() async {
        guard account.signedIn else { return }
        
        let firebaseConfig = FirebaseConfiguration()
        firebaseConfig.configure(account: account, accountService: nil)
        
        self.firebaseConfig = firebaseConfig
        healthKitManager.configure(account: account, config: firebaseConfig)
    }
    
    private func waitAndSync() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        syncData()
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
    
    return HomeView()
        .environmentObject(HealthKitManager.shared)
        .previewWith(standard: USTEPStandard()) {
            USTEPScheduler()
            AccountConfiguration(service: InMemoryAccountService(), activeDetails: details)
        }
}
#endif
