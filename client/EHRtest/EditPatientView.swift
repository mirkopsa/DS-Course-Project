//
//  EditPatientView.swift
//  EHRtest
//
//  Created by Mirko Kopsa on 9.3.2025.
//

import SwiftUI

struct EditPatientView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var patient: Patient
    var onSave: (Patient) -> Void

    var body: some View {
        Form {
            TextField("Name", text: $patient.name)
            TextField("Age", value: $patient.age, formatter: NumberFormatter())
            TextField("SSN", text: $patient.ssn)
        }
        .padding()
        .navigationTitle("Edit Patient")
        .frame(maxWidth: .infinity) // Make sure the form uses the full width
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave(patient)
                    presentationMode.wrappedValue.dismiss()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct EditPatientView_Previews: PreviewProvider {
    static var previews: some View {
        EditPatientView(patient: Patient(id: 1, name: "John Doe", age: 30, ssn: "123-45-6789")) { _ in }
    }
}
