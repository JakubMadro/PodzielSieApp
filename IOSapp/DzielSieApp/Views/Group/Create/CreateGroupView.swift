//
//  CreateGroupView.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//


import SwiftUI

struct CreateGroupView: View {
    @ObservedObject var viewModel: CreateGroupViewModel
    @Environment(\.presentationMode) var presentationMode
    
    init(viewModel: CreateGroupViewModel) {
        self.viewModel = viewModel
    }
    
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informacje o grupie")) {
                    TextField("Nazwa grupy", text: $viewModel.groupName)
                    
                    TextField("Opis (opcjonalnie)", text: $viewModel.groupDescription)
                        .multilineTextAlignment(.leading)
                }
                
                Section(header: Text("Ustawienia")) {
                    Picker("Domyślna waluta", selection: $viewModel.defaultCurrency) {
                        Text("PLN").tag("PLN")
                        Text("EUR").tag("EUR")
                        Text("USD").tag("USD")
                        Text("GBP").tag("GBP")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Button(action: {
                    viewModel.createGroup()
                    if viewModel.error == nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }) {
                    Text("Utwórz grupę")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .disabled(viewModel.isLoading || viewModel.groupName.isEmpty)
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical)
            }
            .navigationTitle("Nowa grupa")
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
