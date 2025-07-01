//
// This source file is part of the USTEP based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

// UtahLogin from our last USTEP App
import SpeziAccount
import SpeziOnboarding
import SwiftUI


//struct UtahLogin: View {
//    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
//    
//   
//    var body: some View {
//        OnboardingView(
//            contentView: {
//                VStack(spacing: 16) {
//                    Text("LOGIN")
//                        .font(.headline)
//                                    .foregroundColor(Color.accentColor)
//                    IconView()
//                        .padding(.top, 10)
//                    
//                    Text("SIGN_IN_SUBTITLE")
//                        .multilineTextAlignment(.center)
//                        .padding(.horizontal)
//                }
//                
//                Spacer() // pushes button to bottom
//            },
//            actionView: {
//                VStack(spacing: 16) {
//                    Button(action: {
//                        onboardingNavigationPath.append(AccountOnboarding.self)
//                    }) {
//                        HStack {
//                            Image(systemName: "envelope.fill")
//                            Text("Email and Password")
//                        }
//                        .font(.headline)
//                        .foregroundColor(Color.accentColor)
//                        .padding()
//                        .frame(maxWidth: .infinity)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 16)
//                                .stroke(Color.accentColor, lineWidth: 2)
//                        )
//                    }
//                    
//                    Divider()
//                }
//                .padding(.horizontal)
//            }
//        )
//    }
//}

struct UtahLogin: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    @AppStorage("isSigningUp") private var isSigningUp = true

    var body: some View {
        if isSigningUp {
            // if the User is Not logging in? Skip this view.
            Color.clear
                .task {
                    onboardingNavigationPath.nextStep()
                }
        } else {
            OnboardingView(
                contentView: {
                    VStack(spacing: 16) {
                        Text("LOGIN")
                            .font(.headline)
                            .foregroundColor(Color.accentColor)

                        IconView()
                            .padding(.top, 10)

                        Text("SIGN_IN_SUBTITLE")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Spacer()
                    }
                },
                actionView: {
                    VStack(spacing: 16) {
                        Button(action: {
                            onboardingNavigationPath.append(AccountOnboarding.self)
                        }) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("Email and Password")
                            }
                            .font(.headline)
                            .foregroundColor(Color.accentColor)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.accentColor, lineWidth: 2)
                            )
                        }

                        Divider()
                    }
                    .padding(.horizontal)
                }
            )
        }
    }
}
#if DEBUG
#Preview {
    OnboardingStack {
        UtahLogin()
    }
        .previewWith {
            OnboardingDataSource()
            AccountConfiguration(
                service: InMemoryAccountService(),
                configuration: .init()
            )
        }
}
#endif
