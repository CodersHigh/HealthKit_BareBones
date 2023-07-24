//
//  HealthStoreManager.swift
//  HealthKit_BareBone
//
//  Created by MentorLingo on 2023/07/02.
//

import Foundation
import HealthKit

class HealthStoreManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    init() {
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        guard let allergiesType = HKObjectType.clinicalType(forIdentifier: .allergyRecord),
              let medicationsType = HKObjectType.clinicalType(forIdentifier: .medicationRecord),
              let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose)
        else {
            fatalError("*** Unable to create the requested types ***")
        }
        
        let shareTypes = Set([HKObjectType.workoutType(), glucoseType])
        let readTypes = Set([HKObjectType.workoutType(), glucoseType, allergiesType, medicationsType])
        
        healthStore.requestAuthorization(toShare: shareTypes , read: readTypes) { success , error in
            if let error = error {
                print("Error requesting authorization:\(error.localizedDescription)")
            }
        }
    }
    
    func addBloodGlucoseData(glucoseValue: Double) {
        guard let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) else { return }
        
        let glucoseUnit = HKUnit.init(from: "mg/dL")
        let glucoseQuantity = HKQuantity(unit: glucoseUnit, doubleValue: glucoseValue)
        let glucoseSample = HKQuantitySample(type: glucoseType, quantity: glucoseQuantity, start: Date(), end: Date())
        
        healthStore.save(glucoseSample) { success, error in
            if let error = error {
                print ("Error saving Glucose data: \(error.localizedDescription)")
            }
        }
    }
    
    func getLatestGlucose(completion: @escaping (Double) -> Void) {
        guard let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) else { return }
        
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: glucoseType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]){ _, samples, error in
            if let error = error {
                print("Error fetching Glucose data: \(error.localizedDescription)")
                completion(0.0)
            } else if let sample = samples?.first as? HKQuantitySample {
                let glucoseUnit = HKUnit.init(from: "mg/dL")
                let glucoseValue = sample.quantity.doubleValue(for: glucoseUnit)
                completion(glucoseValue)
            } else {
                completion(0.0)
            }
        }
        healthStore.execute(query)
    }
    
    
    func fetch7DaysWorkout(completion: @escaping ([String], Double) -> Void) {
        let type = HKObjectType.workoutType()
        let yesterday = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: Date())
        
        let query = HKAnchoredObjectQuery(type: type, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { (query, samples, deletedObjects, anchor, error) in
            if let samples = samples as? [HKWorkout], !samples.isEmpty {
                let activityTypeNames = samples.map { $0.workoutActivityType.name }
                let workoutDuration = samples.reduce(0.0, { $0 + $1.duration })
                print(activityTypeNames)
                print("duration: \(workoutDuration)")
                completion(activityTypeNames, workoutDuration)
            } else {
                print("Error getting 24 hours workout data: \(String(describing: error))")
            }
        }
        healthStore.execute(query)
    }
}
