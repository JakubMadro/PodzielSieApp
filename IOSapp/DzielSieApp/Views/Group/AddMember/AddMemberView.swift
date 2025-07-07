//
//  AddMemberView.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/06/2025.
//

import SwiftUI

struct AddMemberView: View {
    @ObservedObject var viewModel: AddMemberViewModel
    @Environment(\.presentationMode) var presentationMode
    
    init(viewModel: AddMemberViewModel) {
        self.viewModel = viewModel
    }
    
    init(group: Group) {
        self.viewModel = AddMemberViewModel(group: group)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Dane nowego członka")) {
                    TextField("Email", text: $viewModel.memberEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section(header: Text("Uprawnienia")) {
                    Picker("Rola", selection: $viewModel.memberRole) {
                        Text("Administrator").tag("admin")
                        Text("Członek").tag("member")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Button(action: {
                    viewModel.addMember()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Dodaj członka")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .disabled(viewModel.isLoading || viewModel.memberEmail.isEmpty)
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical)
            }
            .navigationTitle("Dodaj nowego członka")
            .navigationBarItems(
                leading: Button("Anuluj") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .disabled(viewModel.isLoading)
            .alert(isPresented: Binding<Bool>(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Alert(
                    title: Text("Błąd"),
                    message: Text(viewModel.error ?? "Wystąpił nieznany błąd"),
                    dismissButton: .default(Text("OK"))
                )
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
}
