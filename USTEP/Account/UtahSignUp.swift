//
// This source file is part of the USTEP based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

// Utah Signup from our last USTEP App
import SpeziAccount
import SpeziOnboarding
import SwiftUI

//
//struct UtahSignUp: View {
//    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
//    var body: some View {
//        OnboardingView(
//            contentView: {
//                VStack(spacing: 16) {
//                    Text("SIGN UP")
//                        .font(.headline)
//                                    .foregroundColor(Color.accentColor)
//
//                    IconView()
//                        .padding(.top, 10)
//                    
//                    Text("SIGN_UP_SUBTITLE")
//                        .multilineTextAlignment(.center)
//                        .padding(.horizontal)
//                }
//                
//                Spacer()
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

struct UtahSignUp: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    @AppStorage("isSigningUp") private var isSigningUp = true

    var body: some View {
        if !isSigningUp {
            // if the user selected Login, not Sign Up — skip this view
            Color.clear
                .task {
                    onboardingNavigationPath.nextStep()
                }
        } else {
            OnboardingView(
                contentView: {
                    VStack(spacing: 16) {
                        Text("SIGN UP")
                            .font(.headline)
                            .foregroundColor(Color.accentColor)

                        IconView()
                            .padding(.top, 10)

                        Text("SIGN_UP_SUBTITLE")
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
        UtahSignUp()
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
