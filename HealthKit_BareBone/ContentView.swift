//
//  ContentView.swift
//  HealthKit_BareBone
//
//  Created by MentorLingo on 2023/07/02.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    
    @ObservedObject private var healthStore = HealthStoreManager()
    
    @State private var glucoseString: String = ""
    @State private var latestGlucose: Double = 0.0
    @State private var workouts :[String] = []
    @State private var duration: Double = 0.0
    
    var body: some View {
        
        VStack (alignment: .leading) {
            Spacer()
            Text("Blood Clucose")
                .font(.title).bold()
            Text("Latest Blood Glucose : \(String(format:"%.1f", latestGlucose))")
                .multilineTextAlignment(.leading)
            HStack {
                TextField("Enter your blood Glucose", text: $glucoseString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Submit") {
                    if let glucoseValue = Double(glucoseString) {
                        healthStore.addBloodGlucoseData(glucoseValue: glucoseValue)
                        glucoseString = ""
                        healthStore.getLatestGlucose{ result in
                            latestGlucose = result
                        }
                    }
                }
            }
            Spacer()
            Text("Workouts").font(.title).bold()
            let workOutString = workouts.joined(separator: " , ")
            Text("지난 7일간 한 운동 : " + workOutString)
            Text("지난 7일간 운동 시간: \(String(format:"%.1f", duration/60)) 분")
            Spacer()
            Spacer()
        }
        .padding()
        .onAppear {
            Task {
                healthStore.getLatestGlucose{ result in
                    latestGlucose = result
                }
                healthStore.fetch7DaysWorkout{ workoutNames, duration in
                    self.workouts = workoutNames
                    self.duration = duration
                }
            }
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
