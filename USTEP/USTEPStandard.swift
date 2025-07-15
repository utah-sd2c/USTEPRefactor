//
// This source file is part of the USTEP based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable function_body_length
@preconcurrency import FirebaseFirestore
@preconcurrency import FirebaseStorage
import HealthKitOnFHIR
import ModelsR4
import OSLog
@preconcurrency import PDFKit.PDFDocument
import Spezi
import SpeziAccount
import SpeziFirebaseAccount
import SpeziFirestore
import SpeziHealthKit
import SpeziOnboarding
import SpeziQuestionnaire
import SwiftUI


actor USTEPStandard: Standard,
                                   EnvironmentAccessible,
                                   HealthKitConstraint,
                                   ConsentConstraint,
                     AccountNotifyConstraint {
    @Application(\.logger) private var logger
    
    @Dependency(FirebaseConfiguration.self) private var configuration
    @Dependency(Account.self) private var account
    
    
    enum SurveyType {
        case edmonton
        case wiq
        case veines
    }
    
    static let surveyPrefix: [SurveyType:String] = [
        .edmonton: "Edmonton",
        .wiq: "WIQ",
        .veines: "VEINES"
    ]
    
    static let surveyCollectionName: [SurveyType:String] = [
        .edmonton: "edmontonsurveys",
        .wiq: "wiqsurveys",
        .veines: "veinessurveys"
    ]
    
    static let surveyCollection: [SurveyType:CollectionReference] = [
        .edmonton: FirebaseConfiguration.edmontonCollection,
        .wiq: FirebaseConfiguration.wiqCollection,
        .veines: FirebaseConfiguration.veinesCollection
    ]
    
    init() {}
    
    
    func add(sample: HKSample) async {
        if FeatureFlags.disableFirebase {
            logger.debug("Received new HealthKit sample: \(sample)")
            return
        }
        
        do {
            // try await healthKitDocument(id: sample.id)
            //    .setData(from: sample.resource)
        } catch {
            logger.error("Could not store HealthKit sample: \(error)")
        }
    }
    
    func remove(sample: HKDeletedObject) async {
        if FeatureFlags.disableFirebase {
            logger.debug("Received new removed healthkit sample with id \(sample.uuid)")
            return
        }
        
        do {
            // try await healthKitDocument(id: sample.uuid).delete()
        } catch {
            logger.error("Could not remove HealthKit sample: \(error)")
        }
    }
    
    // periphery:ignore:parameters isolation
    //    func add(response: ModelsR4.QuestionnaireResponse, isolation: isolated (any Actor)? = #isolation) async {
    //        let id = response.identifier?.value?.value?.string ?? UUID().uuidString
    //
    //        if FeatureFlags.disableFirebase {
    //            let jsonRepresentation = (try? String(data: JSONEncoder().encode(response), encoding: .utf8)) ?? ""
    //            await logger.debug("Received questionnaire response: \(jsonRepresentation)")
    //            return
    //        }
    //
    //        do {
    //             try await configuration.userDocumentReference
    //                .collection("QuestionnaireResponse") // Add all HealthKit sources in a /QuestionnaireResponse collection.
    //                .document(id) // Set the document identifier to the id of the response.
    //                .setData(from: response)
    //        } catch {
    //            await logger.error("Could not store questionnaire response: \(error)")
    //        }
    //    }
    func add(response: ModelsR4.QuestionnaireResponse, isolation: isolated (any Actor)? = #isolation) async {
        let id = response.identifier?.value?.value?.string ?? UUID().uuidString
        
        if FeatureFlags.disableFirebase {
            let jsonRepresentation = (try? String(data: JSONEncoder().encode(response), encoding: .utf8)) ?? ""
            await logger.debug("Received questionnaire response: \(jsonRepresentation)")
            return
        }
        
        do {
            // Get user ID directly from account (like your other code)
            guard let accountId = await account.details?.accountId else {
                await logger.error("No authenticated user found")
                return
            }
            
            try await Firestore.firestore()
                .collection("users")
                .document(accountId)
                .collection("QuestionnaireResponse")
                .document(id)
                .setData(from: response)
        } catch {
            await logger.error("Could not store questionnaire response: \(error)")
        }
    }
    
    // periphery:ignore:parameters isolation
    func scoreByType(response: ModelsR4.QuestionnaireResponse, type: SurveyType, isolation: isolated (any Actor)? = #isolation) -> Int? {
        var score: Int = 0
        var anyFound: Bool = false
        if let answers = response.item {
            for answer in answers {
                // Check if linkId is not nil and starts with the given prefix
                if let linkIdString = answer.linkId.value?.string,
                   let prefix = USTEPStandard.surveyPrefix[type],
                   linkIdString.starts(with: prefix),
                   let firstAnswer = answer.answer?.first, // Get the first answer if it exists
                   let value = firstAnswer.value {
                    var answerScore: Int? = nil // Use optional for safer parsing
                    
                    switch value {
                    case let .coding(codingData):
                        answerScore = Int(codingData.code?.value?.string ?? "")
                        anyFound = true
                    case let .string(stringValue):
                        answerScore = Int(stringValue.value?.string ?? "")
                        anyFound = true
                    default:
                        // Handle other value types if necessary, or just ignore
                        break
                    }
                    if let scoreToAdd = answerScore {
                        score += scoreToAdd
                    }
                }
            }
        }
        return anyFound ? score : nil
    }
    
    func submitByType(
        response: ModelsR4.QuestionnaireResponse,
        type: SurveyType,
        isolation: isolated (any Actor)? = #isolation
    ) async {
        var score: Int = 0
        if let surveyScore = scoreByType(response: response, type: type) {
            score = surveyScore
        } else {
            await logger.log("Trying to submit data that does not exist")
            return
        }

        let id = response.identifier?.value?.value?.string ?? UUID().uuidString

        if FeatureFlags.disableFirebase {
            let jsonRepresentation = (try? String(data: JSONEncoder().encode(response), encoding: .utf8)) ?? ""
            await logger.debug("Received questionnaire response: \(jsonRepresentation)")
            return
        }

        // Filter out questions not matching the prefix
        if let prefix = USTEPStandard.surveyPrefix[type] {
            response.item = response.item?.filter {
                $0.linkId.value?.string.starts(with: prefix) == true
            }
        }

        var userID: String = "PATIENT_ID"
        do {
            userID = try await configuration.userID
            await logger.debug("Successfully got user ID: \(userID)")
        } catch {
            await logger.error("Could not get logged in user's ID: \(error)")
        }

        response.subject = Reference(reference: FHIRPrimitive(FHIRString("Patient/\(userID)")))
        let questionnaireName = USTEPStandard.surveyPrefix[type]?.lowercased() ?? "unknown"
        response.questionnaire = questionnaireName.asFHIRCanonicalPrimitive()

        let summary: [String: Any] = [
            "score": score,
            "type": questionnaireName,
            "surveyId": id,
            "dateCompleted": Timestamp()
        ]

        do {
            try await configuration.userDocumentReference
                .collection("QuestionnaireResponse")
                .document(id)
                .setData(summary)

            if let collection = USTEPStandard.surveyCollection[type] {
                try await collection
                    .document(id)
                    .setData(from: response)
            } else {
                print("Cannot find collection for type: \(type)")
            }
        } catch {
            await logger.error("Could not store questionnaire response: \(error)")
        }

        // Handle file upload for .edmonton type (synchronously)
        if type == .edmonton, let responseItems = response.item {
            for item in responseItems {
                if let answer = item.answer?.first,
                   case let .attachment(attachment) = answer.value,
                   let fileURL = attachment.url?.value?.url {

                    do {
                        let docRef = Firestore.firestore()
                                           .collection("users")
                                           .document(userID)
                                           .collection("QuestionnaireResponse")
                                           .document(id)

                                       let snapshot = try await docRef.getDocument()
                                       if let data = snapshot.data(), data["attachmentURL"] != nil {
                                           print("Attachment already exists, skipping upload.")
                                           break
                                       }
                        let storageRef = Storage.storage().reference()
                        let timestamp = Int(Date().timeIntervalSince1970)
                        let fileName = "edmonton-\(timestamp).heif"
                        let storagePath = "users/\(userID)/edmonton/\(fileName)"
                        let fileRef = storageRef.child(storagePath)

                        // Upload file (awaited)
                        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                            let uploadTask = fileRef.putFile(from: fileURL, metadata: nil)
                            uploadTask.observe(.success) { _ in
                                continuation.resume(returning: ())
                            }
                            uploadTask.observe(.failure) { snapshot in
                                continuation.resume(throwing: snapshot.error ?? NSError(domain: "UploadError", code: -1))
                            }
                        }

                        // Get download URL
                        let downloadURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                            fileRef.downloadURL { url, error in
                                if let url = url {
                                    continuation.resume(returning: url)
                                } else {
                                    continuation.resume(throwing: error ?? NSError(domain: "DownloadURLError", code: -1))
                                }
                            }
                        }
                    } catch {
                        await logger.error("Upload or Firestore update failed: \(error)")
                    }

                    break // Only process first attachment
                }
            }
        }
    }




    private func healthKitDocument(id uuid: UUID) async throws -> FirebaseFirestore.DocumentReference {
        try await configuration.userDocumentReference
            .collection("HealthKit") // Add all HealthKit sources in a /HealthKit collection.
            .document(uuid.uuidString) // Set the document identifier to the UUID of the document.
    }

    func respondToEvent(_ event: AccountNotifications.Event) async {
        if case let .deletingAccount(accountId) = event {
            do {
                // try await configuration.userDocumentReference(for: accountId).delete()
            } catch {
                logger.error("Could not delete user document: \(error)")
            }
        }
    }
    
    /// Stores the given consent form in the user's document directory with a unique timestamped filename.
    ///
    /// - Parameter consent: The consent form's data to be stored as a `PDFDocument`.
    @MainActor
    func store(consent: ConsentDocumentExport) async throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = formatter.string(from: Date())

        guard !FeatureFlags.disableFirebase else {
            guard let basePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                await logger.error("Could not create path for writing consent form to user document directory.")
                return
            }
            
            let filePath = basePath.appending(path: "consentForm_\(dateString).pdf")
            await consent.pdf.write(to: filePath)
            
            return
        }
        
        do {
            guard let consentData = await consent.pdf.dataRepresentation() else {
                await logger.error("Could not store consent form.")
                return
            }

            let metadata = StorageMetadata()
            metadata.contentType = "application/pdf"
            // _ = try await configuration.userBucketReference
            //    .child("consent/\(dateString).pdf")
            //    .putDataAsync(consentData, metadata: metadata) { @Sendable _ in }
        } catch {
            await logger.error("Could not store consent form: \(error)")
        }
    }
}
