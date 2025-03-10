//
//  NetworkingManager.swift
//  EHRtest
//
//  Created by Mirko Kopsa on 9.3.2025.
//

import Foundation

struct Patient: Identifiable, Codable {
    var id: Int?
    var name: String
    var age: Int?
    var ssn: String
}

struct Diagnosis: Identifiable, Codable {
    var id: Int?
    var name: String
    var patient_id: Int?
}

class NetworkManager: ObservableObject {
    @Published var patients: [Patient] = []
    @Published var diagnoses: [Diagnosis] = []

    func fetchPatients() {
        guard let url = URL(string: "http://localhost:8000/patients/") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let patients = try JSONDecoder().decode([Patient].self, from: data)
                    DispatchQueue.main.async {
                        self.patients = patients
                    }
                } catch {
                    print("Error decoding patients: \(error)")
                }
            }
        }.resume()
    }

    func createPatient(name: String, age: Int?, ssn: String) {
        guard let url = URL(string: "http://localhost:8000/patients/") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let newPatient = Patient(id: nil, name: name, age: age, ssn: ssn)
        let jsonData = try? JSONEncoder().encode(newPatient)
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error creating patient: \(error)")
                return
            }

            if let data = data {
                do {
                    let patient = try JSONDecoder().decode(Patient.self, from: data)
                    DispatchQueue.main.async {
                        self.patients.append(patient)
                    }
                } catch {
                    print("Error decoding patient: \(error)")
                }
            }
        }.resume()
    }
    
    func updatePatient(patient: Patient) {
        guard let url = URL(string: "http://localhost:8000/patients/\(patient.id!)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonData = try? JSONEncoder().encode(patient)
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error updating patient: \(error)")
                return
            }

            if let data = data {
                do {
                    let updatedPatient = try JSONDecoder().decode(Patient.self, from: data)
                    DispatchQueue.main.async {
                        if let index = self.patients.firstIndex(where: { $0.id == updatedPatient.id }) {
                            self.patients[index] = updatedPatient
                        }
                    }
                } catch {
                    print("Error decoding patient: \(error)")
                }
            }
        }.resume()
    }
    
    func deletePatient(patientId: Int) {
        guard let url = URL(string: "http://localhost:8000/patients/\(patientId)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error deleting patient: \(error)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    if let index = self.patients.firstIndex(where: { $0.id == patientId }) {
                        self.patients.remove(at: index)
                    }
                }
            } else {
                print("Failed to delete patient: \(String(describing: response))")
            }
        }.resume()
    }
    
    func fetchDiagnoses(for patientId: Int) {
        guard let url = URL(string: "http://localhost:8000/patients/\(patientId)/diagnoses/") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let fetchedDiagnoses = try JSONDecoder().decode([Diagnosis].self, from: data)
                    DispatchQueue.main.async {
                        self.diagnoses.removeAll { $0.patient_id == patientId } // Shows the diagnosis list multiple times otherwise
                        self.diagnoses.append(contentsOf: fetchedDiagnoses)
                    }
                } catch {
                    print("Error decoding diagnoses: \(error)")
                }
            }
        }.resume()
    }
    
    func addDiagnosis(patientId: Int, diagnosisName: String) {
        guard let url = URL(string: "http://localhost:8000/patients/\(patientId)/diagnoses/") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let newDiagnosis = Diagnosis(id: nil, name: diagnosisName, patient_id: patientId)
        let jsonData = try? JSONEncoder().encode(newDiagnosis)
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error adding diagnosis: \(error)")
                return
            }

            if let data = data {
                do {
                    let addedDiagnosis = try JSONDecoder().decode(Diagnosis.self, from: data)
                    DispatchQueue.main.async {
                        self.diagnoses.append(addedDiagnosis)
                    }
                } catch {
                    print("Error decoding diagnosis: \(error)")
                }
            }
        }.resume()
    }
    
    func deleteDiagnosis(patientId: Int, diagnosisId: Int) {
        guard let url = URL(string: "http://localhost:8000/patients/\(patientId)/diagnoses/\(diagnosisId)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error deleting diagnosis: \(error)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    print("Diagnosis deleted: \(diagnosisId)")
                    // Optionally, refetch diagnoses here if you want to make sure UI stays synced
                    self.fetchDiagnoses(for: patientId)
                }
            } else {
                print("Failed to delete diagnosis: \(String(describing: response))")
            }
        }.resume()
    }

}
