//
// This source file is part of the CS342 2023 Utah Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//
// swiftlint:disable identifier_name


import Firebase
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import SpeziAccount
import SwiftUI
import ModelsR4


struct DetailedQuestionnaireView: View {
    @EnvironmentObject var firestoreManager: FirestoreManager
    @State var survey: QuestionnaireResponse?
    var surveyId: String
    var type: String
    var score: Int
    var date: Date
    
    var body: some View {
        NavigationStack {
            Spacer()
            if let survey {
                DQRowView(surveyType: type, score: score, questionnaireResponse: survey)
                    .navigationBarTitle(Text(date, format: .dateTime))
            } else {
                ProgressView()
            }
        }
        .task {
            survey = await querySurveys(type: type, surveyId: surveyId)
        }
    }
    
    
    //        func querySurveys(type: String, surveyId: String) async -> QuestionnaireResponse? {
    //            await withCheckedContinuation { continuation in
    //                let db = Firestore.firestore()
    //                var surveyName = "veinessurveys"
    //                if type == "edmonton" {
    //                    surveyName = "edmontonsurveys"
    //                } else if type == "wiq" {
    //                    surveyName = "wiqsurveys"
    //                }
    //                let docRef = db.collection(surveyName).document(surveyId)
    //                docRef.getDocument(as: QuestionnaireResponse.self) { result in
    //                    switch result {
    //                    case .success(let response):
    //                        print(response)
    //                        continuation.resume(with: .success(response))
    //                    case .failure(let error):
    //                        print(error)
    //                        continuation.resume(with: .success(nil))
    //                    }
    //                }
    //            }
    //        }
    //}
    func querySurveys(type: String, surveyId: String) async -> QuestionnaireResponse? {
        await withCheckedContinuation { continuation in
            let db = Firestore.firestore()
            var surveyName = "veinessurveys"
            if type == "edmonton" {
                surveyName = "edmontonsurveys"
            } else if type == "wiq" {
                surveyName = "wiqsurveys"
            }
            let docRef = db.collection(surveyName).document(surveyId)
            
            docRef.getDocument { snapshot, error in
                if let error = error {
                    print(error)
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists else {
                    continuation.resume(returning: nil)
                    return
                }
                
                do {
                    let response = try snapshot.data(as: QuestionnaireResponse.self)
                    print(response)
                    continuation.resume(returning: response)
                } catch {
                    print(error)
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

// struct DetailedQuestionnaireView_Previews: PreviewProvider {
//    static var previews: some View {
//        DetailedQuestionnaireView(firestoreManager: firestoreManager, surveyId: "TEST", type: "type1", score: 0, date: Date())
//    }
// }
