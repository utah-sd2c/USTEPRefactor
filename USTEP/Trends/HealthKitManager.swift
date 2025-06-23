////
//// This source file is part of the CS342 2023 Utah Team Application project
////
//// SPDX-FileCopyrightText: 2023 Stanford University
////
//// SPDX-License-Identifier: MIT
////
import SwiftUI
import HealthKit
import FirebaseFirestore
import FirebaseAuth
import Spezi
import SpeziAccount
import SpeziFirebaseAccount

public struct DistanceData: Sendable, Identifiable {
    public var id = UUID()
    public var date: String
    public var distance: Double

    public init(date: String, distance: Double) {
        self.date = date
        self.distance = distance
    }
}

public struct StepData: Sendable, Identifiable {
    public var id = UUID()
    public var date: String
    public var steps: Int

    public init(date: String, steps: Int) {
        self.date = date
        self.steps = steps
    }
}

public final class HealthKitManager: @unchecked Sendable, ObservableObject {
    
    @Published public var distanceData: [DistanceData] = []
    @Published public var stepData: [StepData] = []
    @Published public var averageDistance: Double = 0.0
    @Published public var averageSteps: Double = 0.0
    private var refreshTimer: Timer?
    
    @MainActor static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    private let queue = DispatchQueue(label: "healthdataqueue", attributes: .concurrent)
    
    private var account: Account?
    private var config: FirebaseConfiguration?
    
    private var isConfigured = false
    private var initializationTask: Task<Void, Never>?
    
    public init() {

    }
    
    // Method to inject dependencies after Spezi initialization
    public func configure(account: Account?, config: FirebaseConfiguration) {
        self.account = account
        self.config = config
    }
    
    private func ensureConfigured() async {
        guard !isConfigured else { return }
        
        initializationTask?.cancel()

        initializationTask = Task {
            do {
                try await requestAuthorization()
                await fetchDistanceData()
                await fetchStepData()
                await MainActor.run {
                    isConfigured = true
                }
            } catch {
                print("HealthKit authorization failed: \(error)")
            }
        }
        
        await initializationTask?.value
    }
    
    public func requestAuthorizationIfNeeded() {
        Task {
            await ensureConfigured()
        }
    }
    
    // Adding a method to manually start configuration when Spezi is ready
    public func startConfiguration() {
        guard !isConfigured else { return }
        Task {
            await ensureConfigured()
        }
    }
    
    public func requestAuthorization() async throws {
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let readDataTypes: Set<HKObjectType> = [distanceType, stepType]
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: nil, read: readDataTypes) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if !success {
                    continuation.resume(throwing: HealthKitAuthorizationError.authorizationFailed)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // This funciton fetches Distance data mainly to show the data for last 7 days
    public func fetchDistanceData() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)

        let distanceQuery = HKStatisticsCollectionQuery(
            quantityType: distanceType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: Calendar.current.startOfDay(for: now),
            intervalComponents: DateComponents(day: 1)
        )
        
        distanceQuery.initialResultsHandler = { [weak self] _, results, error in
            guard let strongSelf = self else { return }
            
            if let error = error {
                print("Error fetching distance data: \(error)")
                return
            }
            
            guard let results = results else { return }
            var tempDistanceData: [DistanceData] = []
            var tempTotalDistance: Double = 0.0
            results.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                let date = statistics.startDate
                let dateString = strongSelf.dateFormatter(date: date)
                if let sum = statistics.sumQuantity() {
                    let distance = sum.doubleValue(for: HKUnit.mile())
                    tempTotalDistance += distance
                    tempDistanceData.append(DistanceData(date: dateString, distance: distance))
                } else {
                    tempDistanceData.append(DistanceData(date: dateString, distance: 0.0))
                }
            }
            
            // Making arrays immutable before passing to MainActor
            let finalDistanceData = tempDistanceData
            let finalTotalDistance = tempTotalDistance
            let finalAverageDistance = finalDistanceData.isEmpty ? 0 : finalTotalDistance / Double(finalDistanceData.count)
            
            Task { @MainActor in
                strongSelf.distanceData = finalDistanceData
                strongSelf.averageDistance = finalAverageDistance
            }
        }
        
        healthStore.execute(distanceQuery)
    }
    
    // This funciton fetches Step data mainly to show the data for last 7 days
    public func fetchStepData() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let stepQuery = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: Calendar.current.startOfDay(for: now),
            intervalComponents: DateComponents(day: 1)
        )
        
        stepQuery.initialResultsHandler = { [weak self] query, results, error in
            guard let self = self else { return }
            if let error = error {
                print("Error fetching step data: \(error)")
                return
            }
            
            guard let results = results else { return }
            
            var tempStepData: [StepData] = []
            var tempTotalSteps: Int = 0
            
            results.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                let date = statistics.startDate
                let dateString = self.dateFormatter(date: date)
                if let sum = statistics.sumQuantity() {
                    let steps = sum.doubleValue(for: HKUnit.count())
                    tempTotalSteps += Int(steps)
                    tempStepData.append(StepData(date: dateString, steps: Int(steps)))
                } else {
                    tempStepData.append(StepData(date: dateString, steps: 0))
                }
            }
            
            // Making variables immutable before passing
            let finalStepData = tempStepData
            let finalTotalSteps = tempTotalSteps
            
            self.updateStepDataOnMainThread(newStepData: finalStepData, totalSteps: finalTotalSteps)
        }
        
        healthStore.execute(stepQuery)
    }
    
    private func updateStepDataOnMainThread(newStepData: [StepData], totalSteps: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.stepData = newStepData
            self.averageSteps = newStepData.isEmpty ? 0 : Double(totalSteps) / Double(newStepData.count)
        }
    }
    
    private func dateFormatter(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    enum HealthKitAuthorizationError: Error {
        case authorizationFailed
        case configurationNotAvailable
    }
    
    // We use this function to check for data and send data based of our firebase
    public func fetchStepData(from startDate: Date, to endDate: Date) async throws -> [StepData] {
        guard HKHealthStore.isHealthDataAvailable() else {
            return []
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let stepQuery = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: Calendar.current.startOfDay(for: startDate),
            intervalComponents: DateComponents(day: 1)
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            stepQuery.initialResultsHandler = { [weak self] _, results, error in
                guard let self = self else {
                    continuation.resume(returning: [])
                    return
                }
                
                if let error = error {
                    print("Error fetching step data: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = results else {
                    continuation.resume(returning: [])
                    return
                }
                
                var fetchedStepData: [StepData] = []
                
                results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    let date = statistics.startDate
                    let dateString = self.dateFormatter(date: date)
                    if let sum = statistics.sumQuantity() {
                        let steps = sum.doubleValue(for: HKUnit.count())
                        fetchedStepData.append(StepData(date: dateString, steps: Int(steps)))
                    } else {
                        fetchedStepData.append(StepData(date: dateString, steps: 0))
                    }
                }
                
                continuation.resume(returning: fetchedStepData)
            }
            
            healthStore.execute(stepQuery)
        }
    }
    
    nonisolated public func stepCountCollectionExistsAndUpload(completion: @escaping @Sendable (Bool) -> Void) {
        Task {
            await ensureConfigured()
            let result = await performStepCountUpload()
            completion(result)
        }
    }
    
    private func performStepCountUpload() async -> Bool {
        guard let config = self.config else {
            print("Firebase configuration not available - dependencies not injected yet.")
            return false
        }
        
        guard let userDocRef = try? await config.userDocumentReference else {
            print("User document reference not available - Firebase may not be configured.")
            return false
        }
        
        let stepCountCollection = userDocRef.collection("stepCountData")
        
        let documentResult = await withCheckedContinuation { (continuation: CheckedContinuation<DocumentSnapshot?, Never>) in
            userDocRef.getDocument { document, error in
                if let error = error {
                    print("Error fetching user document: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: document)
            }
        }
        
        guard let document = documentResult,
              document.exists,
              let dateJoinedTimestamp = document.get("dateJoined") as? Timestamp else {
            return false
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateJoined = dateJoinedTimestamp.dateValue()
        let todayDateString = dateFormatter.string(from: Date())

        let queryResult = await withCheckedContinuation { (continuation: CheckedContinuation<QuerySnapshot?, Never>) in
            stepCountCollection.order(by: "date", descending: true).limit(to: 1).getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error checking existing step data: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: querySnapshot)
            }
        }
        
        let lastUpdatedDate: Date = {
            if let querySnapshot = queryResult,
               let doc = querySnapshot.documents.first,
               let latestDateString = doc.get("date") as? String,
               let parsed = dateFormatter.date(from: latestDateString) {
                return parsed
            }
            return dateJoined
        }()
        
        do {
            let stepData = try await self.fetchStepData(from: lastUpdatedDate, to: Date())
            
            if stepData.isEmpty {
                return false
            }
            
            let immutableStepData = Array(stepData)
            let immutableLastUpdatedDateString = dateFormatter.string(from: lastUpdatedDate)
            
            if lastUpdatedDate == dateFormatter.date(from: todayDateString) {
                return await uploadStepCountDataAsync(stepData: immutableStepData, date: todayDateString)
            } else {
                let firstUploadSuccess = await uploadStepCountDataAsync(stepData: immutableStepData, date: immutableLastUpdatedDateString)
                
                if !firstUploadSuccess {
                    return false
                }
                
                let missingDaysSuccess = await uploadMissingDaysStepDataAsync(
                    stepData: immutableStepData,
                    from: immutableLastUpdatedDateString,
                    to: todayDateString
                )
                
                if !missingDaysSuccess {
                    return false
                }
                
                return await uploadStepCountDataAsync(stepData: immutableStepData, date: todayDateString)
            }
        } catch {
            print("Failed to fetch step data: \(error)")
            return false
        }
    }
    
    @MainActor
    private func uploadStepCountDataAsync(stepData: [StepData], date: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            uploadStepCountData(stepData: stepData, date: date) { success in
                continuation.resume(returning: success)
            }
        }
    }
    
    @MainActor
    private func uploadMissingDaysStepDataAsync(stepData: [StepData], from: String, to: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            uploadMissingDaysStepData(stepData: stepData, from: from, to: to) { success in
                continuation.resume(returning: success)
            }
        }
    }
    
    @MainActor
    private func uploadStepCountData(stepData: [StepData], date: String, completion: @escaping (Bool) -> Void) {
        guard let config = self.config else {
            completion(false)
            return
        }
        
        guard let docRef = try? config.userDocumentReference.collection("stepCountData").document(date) else {
            completion(false)
            return
        }
        
        let filtered = stepData.filter { $0.date == date }
        let total = filtered.reduce(0) { $0 + $1.steps }
        let timestamp = Timestamp(date: Date())
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                docRef.updateData([
                    "steps": total,
                    "lastUpdatedAt": timestamp
                ]) { error in
                    completion(error == nil)
                }
            } else {
                let dataDict: [String: Any] = [
                    "date": date,
                    "steps": total,
                    "timestamp": timestamp,
                    "lastUpdatedAt": timestamp
                ]
                
                docRef.setData(dataDict) { error in
                    completion(error == nil)
                }
            }
        }
    }
    
    @MainActor
    private func uploadMissingDaysStepData(stepData: [StepData],
                                           from startDateString: String,
                                           to endDateString: String,
                                           completion: @escaping (Bool) -> Void) {
        guard let config = self.config else {
            completion(false)
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let start = formatter.date(from: startDateString),
              let end = formatter.date(from: endDateString) else {
            completion(false)
            return
        }
        
        var current = start
        let group = DispatchGroup()
        var allSuccess = true
        
        while current <= end {
            let dateStr = formatter.string(from: current)
            let dayData = stepData.filter { $0.date == dateStr }
            let steps = dayData.reduce(0) { $0 + $1.steps }
            
            let docRef = try? config.userDocumentReference.collection("stepCountData").document(dateStr)
            let timestamp = Timestamp(date: Date())
            
            guard let docRef = docRef else {
                current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
                continue
            }
            
            group.enter()
            docRef.getDocument { doc, err in
                if let doc = doc, doc.exists {
                    let existing = doc.get("steps") as? Int ?? 0
                    if steps > existing {
                        docRef.updateData([
                            "steps": steps,
                            "lastUpdatedAt": timestamp
                        ]) { err in
                            if err != nil { allSuccess = false }
                            group.leave()
                        }
                    } else {
                        group.leave()
                    }
                } else {
                    let payload: [String: Any] = [
                        "date": dateStr,
                        "steps": steps,
                        "timestamp": timestamp,
                        "lastUpdatedAt": timestamp
                    ]
                    docRef.setData(payload) { err in
                        if err != nil {
                            allSuccess = false
                            print("Failed to set step data for \(dateStr): \(err!.localizedDescription)")
                        }
                        group.leave()
                    }
                }
            }
            
            current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
        }
        
        group.notify(queue: .main) {
            completion(allSuccess)
        }
    }
    

    // We use this function to check for data and send data based of our firebase
    public func fetchDistanceData(from startDate: Date, to endDate: Date) async throws -> [DistanceData] {
        guard HKHealthStore.isHealthDataAvailable() else {
            return []
        }
        
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let distanceQuery = HKStatisticsCollectionQuery(
            quantityType: distanceType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: Calendar.current.startOfDay(for: startDate),
            intervalComponents: DateComponents(day: 1)
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            distanceQuery.initialResultsHandler = { [weak self] _, results, error in
                guard let self = self else {
                    continuation.resume(returning: [])
                    return
                }
                
                if let error = error {
                    print("Error fetching distance data: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = results else {
                    continuation.resume(returning: [])
                    return
                }
                
                var fetchedDistanceData: [DistanceData] = []
                
                results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    let date = statistics.startDate
                    let dateString = self.dateFormatter(date: date)
                    if let sum = statistics.sumQuantity() {
                        let distance = sum.doubleValue(for: HKUnit.mile())
                        fetchedDistanceData.append(DistanceData(date: dateString, distance: distance))
                    } else {
                        fetchedDistanceData.append(DistanceData(date: dateString, distance: 0.0))
                    }
                }
                
                continuation.resume(returning: fetchedDistanceData)
            }
            
            healthStore.execute(distanceQuery)
        }
    }
    
    nonisolated public func distanceDataCollectionExistsAndUpload(completion: @escaping @Sendable (Bool) -> Void) {
        Task {
            await ensureConfigured()
            let result = await performDistanceDataUpload()
            completion(result)
        }
    }
    
    nonisolated private func performDistanceDataUpload() async -> Bool {
        guard let config = self.config else {
            print("Firebase configuration not available - dependencies not injected yet.")
            return false
        }
        
        do {
            let userDocRef = try await config.userDocumentReference
            let distanceDataCollection = userDocRef.collection("distanceData")
            
            let documentResult = await withCheckedContinuation { (continuation: CheckedContinuation<DocumentSnapshot?, Never>) in
                userDocRef.getDocument { document, error in
                    if let error = error {
                        print("Error fetching user document: \(error)")
                        continuation.resume(returning: nil)
                        return
                    }
                    continuation.resume(returning: document)
                }
            }
            
            guard let document = documentResult,
                  document.exists,
                  let dateJoinedTimestamp = document.get("dateJoined") as? Timestamp else {
                return false
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateJoined = dateJoinedTimestamp.dateValue()
            let todayDateString = dateFormatter.string(from: Date())
            
            let queryResult = await getLatestDistanceDataAsync(distanceDataCollection)
            let lastUpdatedDate = getLastUpdatedDateForDistance(queryResult: queryResult,
                                                                dateJoined: dateJoined,
                                                                dateFormatter: dateFormatter)
            
            return await processDistanceDataUpload(lastUpdatedDate: lastUpdatedDate,
                                                   todayDateString: todayDateString,
                                                   dateFormatter: dateFormatter)
        } catch {
            print("User document reference not available - Firebase may not be configured.")
            return false
        }
    }
    
    private func getLatestDistanceDataAsync(_ distanceDataCollection: CollectionReference) async -> QuerySnapshot? {
        await withCheckedContinuation { (continuation: CheckedContinuation<QuerySnapshot?, Never>) in
            distanceDataCollection.order(by: "date", descending: true).limit(to: 1)
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        print("Error checking existing distance data: \(error)")
                        continuation.resume(returning: nil)
                        return
                    }
                    continuation.resume(returning: querySnapshot)
                }
        }
    }
    
    private func getLastUpdatedDateForDistance(queryResult: QuerySnapshot?,
                                               dateJoined: Date,
                                               dateFormatter: DateFormatter) -> Date {
        if let querySnapshot = queryResult,
           !querySnapshot.isEmpty,
           let latestDocument = querySnapshot.documents.first,
           let latestDateString = latestDocument.get("date") as? String,
           let parsed = dateFormatter.date(from: latestDateString) {
            return parsed
        }
        return dateJoined
    }
    
    private func processDistanceDataUpload(lastUpdatedDate: Date,
                                           todayDateString: String,
                                           dateFormatter: DateFormatter) async -> Bool {
        do {
            let distanceData = try await self.fetchDistanceData(from: lastUpdatedDate, to: Date())
            
            if distanceData.isEmpty {
                return false
            }
            
            let immutableDistanceData = Array(distanceData)
            let immutableLastUpdatedDateString = dateFormatter.string(from: lastUpdatedDate)
            
            if lastUpdatedDate == dateFormatter.date(from: todayDateString) {
                return await uploadDistanceDataAsync(distanceData: immutableDistanceData, date: todayDateString)
            } else {
                return await uploadMultipleDaysDistanceData(immutableDistanceData: immutableDistanceData,
                                                            lastUpdatedDateString: immutableLastUpdatedDateString,
                                                            todayDateString: todayDateString)
            }
        } catch {
            print("Failed to fetch distance data: \(error)")
            return false
        }
    }
    
    private func uploadMultipleDaysDistanceData(immutableDistanceData: [DistanceData],
                                                lastUpdatedDateString: String,
                                                todayDateString: String) async -> Bool {
        let firstUploadSuccess = await uploadDistanceDataAsync(distanceData: immutableDistanceData,
                                                               date: lastUpdatedDateString)
        
        if !firstUploadSuccess {
            return false
        }
        
        let missingDaysSuccess = await uploadMissingDaysDistanceDataAsync(
            distanceData: immutableDistanceData,
            from: lastUpdatedDateString,
            to: todayDateString
        )
        
        if !missingDaysSuccess {
            return false
        }
        
        return await uploadDistanceDataAsync(distanceData: immutableDistanceData, date: todayDateString)
    }
    
    @MainActor
    private func uploadDistanceDataAsync(distanceData: [DistanceData], date: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            uploadDistanceData(distanceData: distanceData, date: date) { success in
                continuation.resume(returning: success)
            }
        }
    }
    
    @MainActor
    private func uploadMissingDaysDistanceDataAsync(distanceData: [DistanceData],
                                                    from: String,
                                                    to: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            uploadMissingDaysDistanceData(distanceData: distanceData, from: from, to: to) { success in
                continuation.resume(returning: success)
            }
        }
    }
    
    @MainActor
    private func uploadDistanceData(distanceData: [DistanceData], date: String, completion: @escaping (Bool) -> Void) {
        guard let config = self.config else {
            completion(false)
            return
        }
        
        guard let docRef = try? config.userDocumentReference else {
            completion(false)
            return
        }
        
        let distanceRef = docRef.collection("distanceData").document(date)
        let total = distanceData.filter { $0.date == date }.reduce(0.0) { $0 + $1.distance }
        let lastUpdated = Timestamp(date: Date())
        
        distanceRef.getDocument { document, error in
            var newDistance = total
            if let document = document, document.exists {
                let existing = document.get("distance") as? Double ?? 0.0
                newDistance = max(existing, total)
            }
            
            let payload: [String: Any] = [
                "date": date,
                "distance": newDistance,
                "lastUpdatedAt": lastUpdated
            ]
            
            distanceRef.setData(payload, merge: true) { err in
                if let err = err {
                    print("Failed to upload distance: \(err.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    @MainActor
    private func uploadMissingDaysDistanceData(distanceData: [DistanceData],
                                               from start: String,
                                               to end: String,
                                               completion: @escaping (Bool) -> Void) {
        guard let config = self.config else {
            completion(false)
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let startDate = formatter.date(from: start),
              let endDate = formatter.date(from: end) else {
            completion(false)
            return
        }
        
        var current = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
        var allSuccess = true
        let group = DispatchGroup()
        
        while current <= endDate {
            let dateStr = formatter.string(from: current)
            let daily = distanceData.filter { $0.date == dateStr }
            let total = daily.reduce(0.0) { $0 + $1.distance }
            
            let payload: [String: Any] = [
                "date": dateStr,
                "distance": total,
                "timestamp": Timestamp(date: Date()),
                "lastUpdatedAt": Timestamp(date: Date())
            ]
            
            if let docRef = try? config.userDocumentReference.collection("distanceData").document(dateStr) {
                group.enter()
                docRef.setData(payload, merge: true) { err in
                    if err != nil {
                        allSuccess = false
                    }
                    group.leave()
                }
            }
            
            current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
        }
        
        group.notify(queue: .main) {
            completion(allSuccess)
        }
    }
    // Only syncs data for existing users - does NOT create new users
    public func enhancedSmartSync(completion: @escaping @Sendable (Bool) -> Void) {
        Task {
            await ensureConfigured()
            
            guard let config = self.config else {
                completion(false)
                return
            }
            
            guard let userDocRef = try? await config.userDocumentReference else {
                completion(false)
                return
            }
            
            let userInfo = await getUserInfo(userDocRef: userDocRef)
            
            switch userInfo {
            case .userDoesNotExist:
                completion(false)
                
            case .userExistsNoDateJoined:
                let success = await setDateJoinedAndAddAllData(userDocRef: userDocRef)
                completion(success)
                
            case .userExistsWithDateJoined(let dateJoined):
                let success = await syncExistingUserData(userDocRef: userDocRef, dateJoined: dateJoined)
                completion(success)
            }
        }
    }
    
    private enum UserInfo {
        case userDoesNotExist
        case userExistsNoDateJoined
        case userExistsWithDateJoined(Date)
    }
    
    private func getUserInfo(userDocRef: DocumentReference) async -> UserInfo {
        return await withCheckedContinuation { continuation in
            userDocRef.getDocument { document, error in
                if let error = error {
                    continuation.resume(returning: .userDoesNotExist)
                    return
                }
                
                guard let document = document, document.exists else {
                    continuation.resume(returning: .userDoesNotExist)
                    return
                }
                
                if let dateJoinedTimestamp = document.get("dateJoined") as? Timestamp {
                    let dateJoined = dateJoinedTimestamp.dateValue()
                    continuation.resume(returning: .userExistsWithDateJoined(dateJoined))
                } else {
                    continuation.resume(returning: .userExistsNoDateJoined)
                }
            }
        }
    }
    
    // This function set DateJoined and Add All Data (for existing users without dateJoined)
    private func setDateJoinedAndAddAllData(userDocRef: DocumentReference) async -> Bool {
        let today = Date()
        let updated = await withCheckedContinuation { continuation in
            let updateData: [String: Any] = [
                "dateJoined": Timestamp(date: today),
                "lastUpdated": Timestamp(date: Date())
            ]
            
            userDocRef.updateData(updateData) { error in
                continuation.resume(returning: error == nil)
            }
        }
        
        if !updated {
            return false
        }
        
        return await syncExistingUserData(userDocRef: userDocRef, dateJoined: today)
    }
    
    private func syncExistingUserData(userDocRef: DocumentReference, dateJoined: Date) async -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayDateString = dateFormatter.string(from: Date())
        
        let stepSuccess = await syncStepDataCollection(userDocRef: userDocRef, dateJoined: dateJoined, todayDateString: todayDateString, dateFormatter: dateFormatter)
        
        let distanceSuccess = await syncDistanceDataCollection(userDocRef: userDocRef, dateJoined: dateJoined, todayDateString: todayDateString, dateFormatter: dateFormatter)
        
        let allSuccess = stepSuccess && distanceSuccess
        
        // Update main user document's lastUpdated
        if allSuccess {
            await updateLastUpdatedTimestamp(userDocRef: userDocRef)
        }
        
        return allSuccess
    }
    
    private func syncStepDataCollection(userDocRef: DocumentReference, dateJoined: Date, todayDateString: String, dateFormatter: DateFormatter) async -> Bool {
        let stepCountCollection = userDocRef.collection("stepCountData")
        
        // Check if there's any data in stepCountData collection
        let lastUpdatedDate: Date? = await withCheckedContinuation { (continuation: CheckedContinuation<Date?, Never>) in
            stepCountCollection.order(by: "date", descending: true).limit(to: 1).getDocuments { querySnapshot, error in
                if let error = error {
                    continuation.resume(returning: nil)
                    return
                }
                
                let lastDate: Date
                if let querySnapshot = querySnapshot, !querySnapshot.isEmpty, let latestDocument = querySnapshot.documents.first {
                    let latestDateString = latestDocument.get("date") as? String ?? todayDateString
                    lastDate = dateFormatter.date(from: latestDateString) ?? dateJoined
                } else {
                    lastDate = dateJoined
                }
                continuation.resume(returning: lastDate)
            }
        }
        
        guard let lastUpdatedDate = lastUpdatedDate else {
            return false
        }
        
        do {
            let stepData = try await self.fetchStepData(from: lastUpdatedDate, to: Date())
            
            if stepData.isEmpty {
                return false
            }
            
            if lastUpdatedDate == dateFormatter.date(from: todayDateString) {
                return await uploadStepCountData(userDocRef: userDocRef, stepData: stepData, date: todayDateString)
            } else {
                // If last updated date is not today, update previous days and then today's data
                let firstUpload = await uploadStepCountData(userDocRef: userDocRef, stepData: stepData, date: dateFormatter.string(from: lastUpdatedDate))
                
                if !firstUpload {
                    return false
                }
                
                let missingDays = await uploadMissingDaysStepData(userDocRef: userDocRef, stepData: stepData, from: dateFormatter.string(from: lastUpdatedDate), to: todayDateString)
                
                if !missingDays {
                    return false
                }
                
                return await uploadStepCountData(userDocRef: userDocRef, stepData: stepData, date: todayDateString)
            }
        } catch {
            return false
        }
    }

    private func syncDistanceDataCollection(userDocRef: DocumentReference, dateJoined: Date, todayDateString: String, dateFormatter: DateFormatter) async -> Bool {
        let distanceDataCollection = userDocRef.collection("distanceData")
        
        let lastUpdatedDate: Date? = await withCheckedContinuation { (continuation: CheckedContinuation<Date?, Never>) in
            distanceDataCollection.order(by: "date", descending: true).limit(to: 1).getDocuments { querySnapshot, error in
                if let error = error {
                    continuation.resume(returning: nil)
                    return
                }
                
                let lastDate: Date
                if let querySnapshot = querySnapshot, !querySnapshot.isEmpty, let latestDocument = querySnapshot.documents.first {
                    let latestDateString = latestDocument.get("date") as? String ?? todayDateString
                    lastDate = dateFormatter.date(from: latestDateString) ?? dateJoined
                } else {
                    lastDate = dateJoined
                }
                continuation.resume(returning: lastDate)
            }
        }
        
        guard let lastUpdatedDate = lastUpdatedDate else {
            return false
        }
        
        do {
            let distanceData = try await self.fetchDistanceData(from: lastUpdatedDate, to: Date())
            
            if distanceData.isEmpty {
                return false
            }
            
            if lastUpdatedDate == dateFormatter.date(from: todayDateString) {
                return await uploadDistanceData(userDocRef: userDocRef, distanceData: distanceData, date: todayDateString)
            } else {
                let firstUpload = await uploadDistanceData(userDocRef: userDocRef, distanceData: distanceData, date: dateFormatter.string(from: lastUpdatedDate))
                
                if !firstUpload {
                    return false
                }
                
                let missingDays = await uploadMissingDaysDistanceData(userDocRef: userDocRef, distanceData: distanceData, from: dateFormatter.string(from: lastUpdatedDate), to: todayDateString)
                
                if !missingDays {
                    return false
                }
                
                return await uploadDistanceData(userDocRef: userDocRef, distanceData: distanceData, date: todayDateString)
            }
        } catch {
            return false
        }
    }
    
    private func uploadStepCountData(userDocRef: DocumentReference, stepData: [StepData], date: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            let stepCountCollection = userDocRef.collection("stepCountData")
            let filteredStepData = stepData.filter { $0.date == date }
            let totalSteps = filteredStepData.reduce(0) { $0 + $1.steps }
            let lastUpdatedAt = Timestamp(date: Date())
            let docRef = stepCountCollection.document(date)
            
            docRef.getDocument { document, error in
                if let document = document, document.exists {
                    docRef.updateData([
                        "steps": totalSteps,
                        "lastUpdatedAt": lastUpdatedAt
                    ]) { error in
                        continuation.resume(returning: error == nil)
                    }
                } else {
                    let dataDict: [String: Any] = [
                        "date": date,
                        "steps": totalSteps,
                        "timestamp": lastUpdatedAt,
                        "lastUpdatedAt": lastUpdatedAt
                    ]
                    
                    docRef.setData(dataDict) { error in
                        continuation.resume(returning: error == nil)
                    }
                }
            }
        }
    }
    
    private func uploadMissingDaysStepData(userDocRef: DocumentReference, stepData: [StepData], from startDateString: String, to endDateString: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            guard let startDate = dateFormatter.date(from: startDateString),
                  let endDate = dateFormatter.date(from: endDateString) else {
                continuation.resume(returning: false)
                return
            }
            
            var currentDate = startDate
            let group = DispatchGroup()
            var allUploadsSuccess = true
            
            while currentDate <= endDate {
                let currentDateString = dateFormatter.string(from: currentDate)
                let currentStepData = stepData.filter { $0.date == currentDateString }
                let totalSteps = currentStepData.reduce(0) { $0 + $1.steps }
                let timestamp = Timestamp(date: Date())
                
                let dataDict: [String: Any] = [
                    "date": currentDateString,
                    "steps": totalSteps,
                    "timestamp": timestamp,
                    "lastUpdatedAt": timestamp
                ]
                
                let stepCountCollection = userDocRef.collection("stepCountData")
                let docRef = stepCountCollection.document(currentDateString)
                
                group.enter()
                
                docRef.getDocument { document, error in
                    if let document = document, document.exists {
                        let existingSteps = document.get("steps") as? Int ?? 0
                        if totalSteps > existingSteps {
                            docRef.updateData([
                                "steps": totalSteps,
                                "lastUpdatedAt": timestamp
                            ]) { error in
                                if error != nil {
                                    allUploadsSuccess = false
                                }
                                group.leave()
                            }
                        } else {
                            group.leave()
                        }
                    } else {
                        docRef.setData(dataDict) { error in
                            if error != nil {
                                allUploadsSuccess = false
                            }
                            group.leave()
                        }
                    }
                }
                
                currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
            }
            
            group.notify(queue: .main) {
                continuation.resume(returning: allUploadsSuccess)
            }
        }
    }
    
    private func uploadDistanceData(userDocRef: DocumentReference, distanceData: [DistanceData], date: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            let distanceDataCollection = userDocRef.collection("distanceData")
            let filteredDistanceData = distanceData.filter { $0.date == date }
            let totalDistance = filteredDistanceData.reduce(0.0) { $0 + $1.distance }
            let lastUpdatedAt = Timestamp(date: Date())
            let docRef = distanceDataCollection.document(date)
            
            docRef.getDocument { document, error in
                if let error = error {
                    continuation.resume(returning: false)
                    return
                }
                
                var newDistance = totalDistance
                if let document = document, document.exists {
                    let existingDistance = document.get("distance") as? Double ?? 0.0
                    newDistance = max(existingDistance, totalDistance)
                }
                
                let dataDict: [String: Any] = [
                    "date": date,
                    "distance": newDistance,
                    "lastUpdatedAt": lastUpdatedAt
                ]
                
                docRef.setData(dataDict, merge: true) { error in
                    continuation.resume(returning: error == nil)
                }
            }
        }
    }
    
    private func uploadMissingDaysDistanceData(userDocRef: DocumentReference, distanceData: [DistanceData], from startDateString: String, to endDateString: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            guard let startDate = dateFormatter.date(from: startDateString),
                  let endDate = dateFormatter.date(from: endDateString) else {
                continuation.resume(returning: false)
                return
            }
            
            var currentDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
            var allUploadsSuccess = true
            let group = DispatchGroup()
            
            while currentDate <= endDate {
                let currentDateString = dateFormatter.string(from: currentDate)
                let currentDistanceData = distanceData.filter { $0.date == currentDateString }
                let totalDistance = currentDistanceData.reduce(0.0) { $0 + $1.distance }
                let timestamp = Timestamp(date: Date())
                
                let dataDict: [String: Any] = [
                    "date": currentDateString,
                    "distance": totalDistance,
                    "timestamp": timestamp,
                    "lastUpdatedAt": timestamp
                ]
                
                let distanceDataCollection = userDocRef.collection("distanceData")
                let docRef = distanceDataCollection.document(currentDateString)
                
                group.enter()
                
                docRef.setData(dataDict) { error in
                    if error != nil {
                        allUploadsSuccess = false
                    }
                    group.leave()
                }
                
                currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
            }
            
            group.notify(queue: .main) {
                continuation.resume(returning: allUploadsSuccess)
            }
        }
    }
    
    private func updateLastUpdatedTimestamp(userDocRef: DocumentReference) async {
        _ = await withCheckedContinuation { continuation in
            userDocRef.updateData(["lastUpdated": Timestamp(date: Date())]) { error in
                continuation.resume(returning: ())
            }
        }
    }
}
