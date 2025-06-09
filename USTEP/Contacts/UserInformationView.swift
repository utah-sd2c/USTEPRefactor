//
// This source file is part of the CS342 2023 Utah Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

// UserInformationView from our Old USTEP App
import SpeziAccount
import SpeziFirebaseAccount
import SwiftUI

struct UserInformationView: View {
    @Environment(Account.self) private var account
    @State private var logOut = false
    @State private var needHelp = false
    @State private var surveyHistory = false

    var body: some View {
        VStack(spacing: 8) {
            InfoRow(field: "EMAIL", value: account.details?.email ?? "Not Available")
            InfoRow(field: "DIAGNOSIS", value: "N/A")



            Spacer(minLength: 0)

            // Navigation menu
            MenuButton(
                eventBool: $surveyHistory,
                buttonLabel: "Survey History",
                foregroundColor: Color.accentColor,
                backgroundColor: Color(.white)
            )
            .sheet(isPresented: $surveyHistory) {
//                SurveyHistoryList()
            }
            .padding(.bottom, -15)
            MenuButton(
                eventBool: $needHelp,
                buttonLabel: "Need help?",
                foregroundColor: Color.accentColor,
                backgroundColor: Color(.white)
            )
            .sheet(isPresented: $needHelp) {
                HelpPage()
            }
            .padding(.bottom, -15)
            LogoutButton(
                eventBool: $logOut,
                buttonLabel: "Logout",
                foregroundColor: Color(.white),
                backgroundColor: Color.accentColor)
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 10)
    }
}
