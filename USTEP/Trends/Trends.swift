// This source file is part of the CS342 2023 Utah Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable identifier_name
// swiftlint:disable closure_body_length
// swiftlint:disable large_tuple


import SpeziAccount
import SwiftUI
//import class SpeziFHIR.FHIR
import FirebaseAuth
import FirebaseFirestore
import SpeziOnboarding

public struct Trends: View {
    @EnvironmentObject var firestoreManager: FirestoreManager
        @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var showStepCount = false
    @State private var showStepCountnew = false
    @State private var showsixminutewalktestContentView = false
    @State private var showWalkTestChart = false
    @State private var showEdmonton = false
    @State private var showVeines = false
    @State private var showWIQ = false
    // we will check whether we have these surveys in the db
    @State private var edmonton_db = false
    @State private var veins_db = false
    @State private var wiq_db = false
    @State private var showDistanceTraveled = false
    @State private var averageDistance: Double = 0.0
    @State private var showOnboarding = false
    @Environment(Account.self) private var account: Account?
    
    @Binding private var presentingAccount: Bool
    
    public var body: some View {
        NavigationStack {
            //            Button(action: {
            //                showOnboarding = true
            //            }, label: {
            //                Image(systemName: "info.circle.fill")
            //                    .foregroundColor(.accentColor)
            //                    .font(.system(size: 25))
            //            })
            //            .frame(maxWidth: .infinity, alignment: .leading)
            //               .padding(.leading, 20)
            //               .padding(.top, 10)
            //            .sheet(isPresented: $showOnboarding) {
            //                OnboardingViewExample()
            //            }
            ScrollView {
                VStack {
                    Text("Trends")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                    
                    Spacer()
                    VStack  {
                        Text("Activity")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top, 10)
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Gets data from healthkit manager file
                        DataCard(
                            icon: "shoeprints.fill",
                            title: "Average Step Count",
                            unit: "steps",
                            color: Color.green
                        )
                        .padding(.vertical, 10)
                        .onTapGesture {
                            self.showStepCountnew.toggle()
                        }
                        .sheet(isPresented: $showStepCountnew) {
                                                        StepCountChartnew()
                            
                            
                        }
                    }
                    // gets distance data from healtkit manager file
                    DataCard(
                        icon: "figure.walk",
                        title: "Average Distance Traveled",
                        unit: "mi",
                        color: Color.orange
                        
                    )
                    .padding(.vertical, 10)
                    .onTapGesture {
                        self.showDistanceTraveled.toggle()
                    }
                    .sheet(isPresented: $showDistanceTraveled) {
                                                    DistanceTraveledChart()
                                                        .environmentObject(healthKitManager)
                    }
                    
                                        Text("Questionnaires")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .padding(.top, 10)
                                            .padding(.bottom, 10)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        ForEach(getKeys(dict: firestoreManager.surveys), id: \.self) { survey in
                                            if survey == "edmonton"{
                                                DataCard(
                                                    icon: "figure.run",
                                                    title: "Latest EFS Score",
                                                    unit: "points",
                                                    color: Color.blue
                                                )
                                                .padding(.vertical, 10)
                                                .onTapGesture {
                                                    self.showEdmonton.toggle()
                                                }
                                                .sheet(isPresented: $showEdmonton) {
                                                                                            SurveyChart(title: "Edmonton Frail Scale", surveyType: "edmonton")
                                                }
                                            } else if survey == "veines" {
                                                DataCard(icon: "list.clipboard.fill", title: "Veines Survey Score", unit: "points", color: Color.purple)
                                                    .padding(.vertical, 10)
                                                    .onTapGesture {
                                                        self.showVeines.toggle()
                                                    }
                                                    .sheet(isPresented: $showVeines) {
                                                                                                    SurveyChart(title: "Veines Survey", surveyType: "veines")
                                                    }
                                            } else if survey == "wiq" {
                                                DataCard(icon: "figure.walk", title: "WIQ Survey Score", unit: "points", color: Color.red)
                                                    .padding(.vertical, 10)
                                                    .onTapGesture {
                                                        self.showWIQ.toggle()
                                                    }
                                                    .sheet(isPresented: $showWIQ) {
                                                                                                    SurveyChart(title: "WIQ Survey", surveyType: "wiq")
                                                    }
                                            }
                                        }
                    
                    Text("Six Minute Walk Test")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    DataCard(
                        icon: "figure.walk",
                        title: "Six Minute Walk Test",
                        unit: "mi",
                        color: Color.red
                    )
                    .padding(.vertical, 10)
                    .onTapGesture {
                        showsixminutewalktestContentView.toggle()
                    }
                    .sheet(isPresented: $showsixminutewalktestContentView) {
                        NavigationView {
                            //                                        sixminutewalktestContentView()
                            //                                            .environmentObject(firestoreManager)
                        }
                    }
                } .padding(.horizontal)
                    .padding(.bottom)
            }
            .toolbar {
                if account != nil {
                    AccountButton(isPresented: $presentingAccount)
                }
            }
            .scrollIndicators(.never)
        }
        
        .onAppear {
            //
            //            if let user = Auth.auth().currentUser {
            //                let userUID = user.uid
            //                Task {
            //                    await firestoreManager.fetchAllIncludingWalkTest(userUID: userUID)
            //                }
            //            } else {
            //                print("User is not logged in.")
            //            }
            //                        Task {
            //                                       await healthKitManager.fetchDistanceData()
            //                                       await healthKitManager.fetchStepData()
            //                                   }
            
            //            DataCard(#imageLiteral(resourceName: "simulator_screenshot_349651C7-2510-4B06-943D-963D2708613E.png")
            //                            icon: "figure.walk",
            //                            title: "Six Minute Walk Test",
            //                            unit: "mi",
            //                            color: Color.blue
            //                        )
            //                        .padding(.vertical, 10)
            //                        .onTapGesture {
            //                            self.ContentView.toggle()
            //                        }
            ////                        .sheet(isPresented: $showWalkTestChart) {
            ////                                            SixMinuteWalkTestChartView()
            ////
            //                                 }
            Spacer()
            
            
            //                    // temporary fix
            //                        .navigationBarTitle("Trends")
        }
    }
    public init(presentingAccount: Binding<Bool>) {
        self._presentingAccount = presentingAccount
    }
    func getKeys(dict: [String: [(dateCompleted: Date, score: Int, surveyId: String)]]) -> [String] {
        let sortedDict = dict.sorted(by: { $0.0 < $1.0 })
        let keys = sortedDict.map { $0.0 }
        return keys
    }
}
    // This just removes this section from being counted in our % "test coverage"
    //#if !TESTING
    //
    //struct Trends_Previews: PreviewProvider {
    //    static var previews: some View {
    //        Trends()
    ////            .environmentObject(FHIR())
    ////            .environmentObject(HealthKitManager())
    //    }
    //}
    //#endif
    
#if DEBUG
    private struct TrendsPreviewWrapper: View {
        @State private var presentingAccount = false
        
        var body: some View {
            Trends(presentingAccount: $presentingAccount)
                .previewWith(standard: USTEPStandard()) {
                    AccountConfiguration(
                        service: InMemoryAccountService(),
                        configuration: .init()
                    )
                }
        }
    }
    
    #Preview {
        TrendsPreviewWrapper()
    }
#endif
    
    
    // Latest Normal Onboarding from Spezi Onboarding
    //#endif
    //struct OnboardingViewExample: View {
    //    @State private var isOnboardingFinished = false
    //
    //    var body: some View {
    //        if isOnboardingFinished {
    //            EndScreenView()
    //        } else {
    //            OnboardingView(
    //                title: "Welcome to the Trend's Tab Onboarding!",
    //                subtitle: "",
    //                areas: [
    //                    .init(
    //                        icon: Image(systemName: "shoeprints.fill"),
    //                        title: "Average Step Count",
    //                        description: "This will show you the steps of last 7 days along with an average count of it too!"
    //                    ),
    //                    .init(
    //                        icon: Image(systemName: "figure.walk"),
    //                        title: "Average Distance Travelled",
    //                        description: ""
    //                    ),
    //                    .init(
    //                        icon: Image(systemName: "figure.run"),
    //                        title: "Latest EFS Score",
    //                        description: ""
    //                    ),
    //                    .init(
    //                        icon: Image(systemName: "list.clipboard.fill"),
    //                        title: "Veines Survey Score",
    //                        description: ""
    //                    ),
    //                    .init(
    //                        icon: Image(systemName: "figure.walk"),
    //                        title: "WIQ Survey Score",
    //                        description: ""
    //                    ),
    //                    .init(
    //                        icon: Image(systemName: "figure.walk"),
    //                        title: "Six Minute Walk Test",
    //                        description: ""
    //                    )
    //                ],
    //                actionText: "Finish"
    //            ) {
    //                isOnboardingFinished = true // Marks onboarding as finished
    //            }
    //        }
    //    }
    //}
    //
    //
    //
    ////  End Screen View
    //struct EndScreenView: View {
    //    var body: some View {
    //        VStack {
    //            Spacer()
    //            Text("You're all set!")
    //                .font(.largeTitle)
    //                .fontWeight(.bold)
    //                .padding(.bottom, 10)
    //
    //            Text("Thank you!")
    //                .font(.body)
    //                .multilineTextAlignment(.center)
    //                .padding(.horizontal, 20)
    //
    //            Spacer()
    //
    //            Image(systemName: "checkmark.seal.fill")
    //                .resizable()
    //                .scaledToFit()
    //                .frame(width: 100, height: 100)
    //                .foregroundColor(.green)
    //                .padding()
    //
    //            Spacer()
    //        }
    //    }
    //}
