//
// This source file is part of the USTEP based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

/// Constants shared across the Spezi Teamplate Application to access storage information including the `AppStorage` and `SceneStorage`
enum StorageKeys {
    // MARK: - Onboarding
    /// A `Bool` flag indicating of the onboarding was completed.
    static let onboardingFlowComplete = "onboardingFlow.complete"
    
    // MARK: - Home
    /// The currently selected home tab.
    static let homeTabSelection = "home.tabselection"
    /// The TabView customization on iPadOS
    static let tabViewCustomization = "home.tab-view-customization"
    
    // MARK: - Condition
    /// The conditions the patients can choose from
    public static let conditions = ["Arterial Disease", "Venous Disease", "I Don't Know"]
    
    // MARK: - Survey Results
    /// The results of edmonton survey that patient will see
    public static let surveyResult = [
        "Healthy": "You are doing well and do not have many health concerns.",
        "Vulnerable": "You have some health concerns and may benefit from extra support and care.",
        "Frail": "You have significant health concerns and may need help with daily tasks and activities."
    ]
}
