//
//  EditDiagnosesView.swift
//  EHRtest
//
//  Created by Mirko Kopsa on 9.3.2025.
//

import SwiftUI
import Foundation

struct OpenAIService {
    let apiKey = "PLACE-API-KEY-HERE"
    let model = "gpt-3.5-turbo"

    func fetchDiagnosis(for condition: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are a medical assistant that provide the ICD-10 diagnosis code followed by the name and nothing else for a given condition. Separate the code and name with a single space."],
                ["role": "user", "content": condition]
            ],
            "max_tokens": 20,
            "temperature": 0.3
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("Error encoding request: \(error)")
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Request failed: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            // Print the raw API response
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("API RESPONSE: \(rawResponse)")
            }

            do {
                let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                
                // Handle errors
                if let errorMessage = result.error?.message {
                    print("PI Error: \(errorMessage)")
                    completion("Error: \(errorMessage)")
                    return
                }
                completion(result.choices?.first?.message.content)
            } catch {
                print("Decoding error: \(error)")
                completion(nil)
            }
        }.resume()
    }
}

struct OpenAIResponse: Codable {
    let choices: [Choice]?
    let error: OpenAIError?
}

struct Choice: Codable {
    let message: OpenAIMessage
}

struct OpenAIMessage: Codable {
    let content: String
}

struct OpenAIError: Codable {
    let message: String
}

struct EditDiagnosesView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var patient: Patient
    @State private var condition: String = ""
    @State private var diagnosis: String?
    @State private var isLoading = false
    @State private var newDiagnosisName: String = ""
    @State private var diagnoses: [Diagnosis] = []
    let openAIService = OpenAIService()
    var onSave: (Diagnosis) -> Void

    var body: some View {
        VStack() {
            Section(header: Text("Describe the Diagnosis")) {
                TextField("", text: $condition)
                Button(action: fetchDiagnosis) {
                    HStack {
                        if isLoading {
                            ProgressView().controlSize(.small)
                        } else {
                            Text("Suggest ICD-10 Diagnosis")
                        }
                    }
                }
                .disabled(condition.isEmpty || isLoading)
                TextField("Diagnosis", text: $newDiagnosisName)
            }
            .padding()
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add Diagnosis") {
                    let newDiagnosis = Diagnosis(id: nil, name: newDiagnosisName, patient_id: patient.id)
                    onSave(newDiagnosis)
                    diagnoses.append(newDiagnosis)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(newDiagnosisName.isEmpty)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    func fetchDiagnosis() {
        isLoading = true
        openAIService.fetchDiagnosis(for: condition) { result in
            DispatchQueue.main.async {
                self.newDiagnosisName = result ?? "Unkown"
                self.isLoading = false
            }
        }
    }
}
