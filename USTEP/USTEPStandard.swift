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
    func add(response: ModelsR4.QuestionnaireResponse, isolation: isolated (any Actor)? = #isolation) async {
        let id = response.identifier?.value?.value?.string ?? UUID().uuidString
        
        if FeatureFlags.disableFirebase {
            let jsonRepresentation = (try? String(data: JSONEncoder().encode(response), encoding: .utf8)) ?? ""
            await logger.debug("Received questionnaire response: \(jsonRepresentation)")
            return
        }
        
        do {
            // try await configuration.userDocumentReference
            //    .collection("QuestionnaireResponse") // Add all HealthKit sources in a /QuestionnaireResponse collection.
            //    .document(id) // Set the document identifier to the id of the response.
            //    .setData(from: response)
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
    
    func submitByType(response: ModelsR4.QuestionnaireResponse,
                          type: SurveyType,
                          isolation: isolated (any Actor)? = #isolation) async {
        var score: Int = 0
        if let surveyScore: Int = scoreByType(response: response, type: type) {
            // We can process this request, as there is at least one question of the specified type
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
        
        // Make a deep copy of the response so we don't modify the object passed in
        var copiedResponse: ModelsR4.QuestionnaireResponse
        do{
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            let data = try encoder.encode(response)
            copiedResponse = try decoder.decode(ModelsR4.QuestionnaireResponse.self, from: data)
        } catch {
            await logger.error("Error copying questionnaire response for processing: \(error)")
            return
        }
        
        
        // Filter out any questions that don't start with the specified prefix
        var indexesToRemove: [Int] = []
        if let answers = copiedResponse.item {
            for (ind, answer) in answers.enumerated() {
                // Check if linkId is not nil and starts with the given prefix
                if let linkIdString = answer.linkId.value?.string,
                   let prefix = USTEPStandard.surveyPrefix[type],
                   linkIdString.starts(with: prefix) {
                    // We'll process this item
                    // TODO: Get the URL, if any, from this and upload that file?
                } else {
                    // We won't process this item
                    indexesToRemove.append(ind)
                }
            }
        }
        for ind in indexesToRemove.reversed() {
            copiedResponse.item?.remove(at: ind)
        }
        
        var userID: String = "PATIENT_ID"
        do {
            userID = try await configuration.userID
            await logger.debug("Successfully got user ID: \(userID)")
        } catch {
            await logger.error("Could not get logged in user's ID: \(error)")
        }
        response.subject = Reference(reference: FHIRPrimitive(FHIRString("Patient/\(userID)")))
        
        let questionnaireName: String = USTEPStandard.surveyPrefix[type]?.lowercased() ?? "unknown"
        copiedResponse.questionnaire = questionnaireName.asFHIRCanonicalPrimitive()
        
        // Create the summary that is stored in the user collection
        let summary: [String: Any] = [
            "score": score,
            "type": questionnaireName,
            "surveyId": id,
            "dateCompleted": Timestamp()
        ] as [String: Any]
        
        do {
            try await configuration.userDocumentReference
                .collection("QuestionnaireResponse") // Add all HealthKit sources in a /QuestionnaireResponse collection.
                .document(id) // Set the document identifier to the id of the response.
                .setData(summary)
            if let collection = USTEPStandard.surveyCollection[type] {
                try await collection
                    .document(id)
                    .setData(from: copiedResponse)
            } else {
                print("Cannot find collection for type: \(type)")
            }
        } catch {
            await logger.error("Could not store questionnaire response: \(error)")
        }
        
        // TODO: Upload the clock draw as well
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
