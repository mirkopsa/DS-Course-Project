//
//  ContentView.swift
//  EHRtest
//
//  Created by Mirko Kopsa on 9.3.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var networkManager = NetworkManager()
    @State private var name = ""
    @State private var age = ""
    @State private var ssn = ""
    @State private var selectedPatientDetails: Patient?
    @State private var selectedPatientDiagnoses: Patient?

    var body: some View {
        VStack {
            List(networkManager.patients) { patient in
                VStack(alignment: .leading) {
                    Text(patient.name)
                        .font(.headline)
                    Text("Age: \(patient.age ?? 0)")
                    Text("SSN: \(patient.ssn)")
                    Text("Diagnoses: ")
                    .onAppear {
                        networkManager.fetchDiagnoses(for: patient.id!)
                    }
                    ForEach(networkManager.diagnoses.filter { $0.patient_id == patient.id }) { diagnosis in
                        HStack {
                            Text(diagnosis.name)
                            Spacer()
                            Button(action: {
                                // Call the deleteDiagnosis method when the user deletes a diagnosis
                                networkManager.deleteDiagnosis(patientId: patient.id!, diagnosisId: diagnosis.id!)
                                networkManager.diagnoses.removeAll { $0.id == diagnosis.id }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    HStack {
                        Button("New Diagnosis") {
                            selectedPatientDiagnoses = patient
                        }
                        Spacer()
                        Button("Edit") {
                            selectedPatientDetails = patient
                        }
                        Button("Delete Patient") {
                            networkManager.deletePatient(patientId: patient.id!)
                        }
                        .foregroundColor(.red)
                    }
                    .padding(.bottom, 12)
                }
            }
            Form {
                TextField("Name", text: $name)
                TextField("Age", text: $age)
                TextField("SSN", text: $ssn)
                Button("Add Patient") {
                    if let age = Int(age) {
                        networkManager.createPatient(name: name, age: age, ssn: ssn)
                        name = ""
                        self.age = ""
                        ssn = ""
                    }
                }
            }
        }
        .sheet(item: $selectedPatientDetails) { patient in
            EditPatientView(patient: patient) { updatedPatient in
                networkManager.updatePatient(patient: updatedPatient)
            }
        }
        .sheet(item: $selectedPatientDiagnoses) { patient in
            EditDiagnosesView(patient: patient) { newDiagnosis in
                networkManager.addDiagnosis(patientId: patient.id!, diagnosisName: newDiagnosis.name)
                networkManager.fetchDiagnoses(for: patient.id!)
            }
        }
        .onAppear {
            networkManager.fetchPatients()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                for patient in networkManager.patients {
                    networkManager.fetchDiagnoses(for: patient.id!)
                }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
