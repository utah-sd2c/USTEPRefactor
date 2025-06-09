//
// This source file is part of the USTEP based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

// New UserView
import SwiftUI
import SpeziAccount
import SpeziFirebaseAccount

struct UserView: View {
    @Environment(Account.self) private var account
    @Environment(FirebaseConfiguration.self) private var firebaseConfig

    var body: some View {
        Group {
            if account.signedIn,
               let details = account.details {
            } else {
                ProgressView("Loading...")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    UserView()
        .previewWith(standard: USTEPStandard()) {
            FirebaseConfiguration()
            AccountConfiguration(
                service: InMemoryAccountService(),
                configuration: .init() 
            )
        }
}


// Commented out old UserView
        //    @ViewBuilder
        //    private func signedInView(name: PersonNameComponents, email: String?) -> some View {
        //        HStack(spacing: 16) {
        //            UserProfileView(name: name)
        //                .frame(width: 40, height: 40)
        //
        //            VStack(alignment: .leading, spacing: 4) {
        //                Text(name.formatted(.name(style: .medium)))
        //                    .font(.headline)
        //                if let email {
        //                    Text(email)
        //                        .font(.subheadline)
        //                        .foregroundColor(.secondary)
        //                }
        //            }
        //
        //            Spacer()
        //        }
        //    }
        
        //    @ViewBuilder
        //    private var loadingView: some View {
        //        VStack(spacing: 8) {
        //            ProgressView()
        //            Text("Loading account info...")
        //                .font(.footnote)
        //                .foregroundColor(.gray)
        //        }
        //        .frame(maxWidth: .infinity)
        //    }
        //}

