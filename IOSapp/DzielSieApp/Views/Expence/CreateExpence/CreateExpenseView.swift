//
//  CreateExpenseView.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 06/04/2025.
//

import SwiftUI

struct CreateExpenseView: View {
    let groupId: String
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = CreateExpenseViewModel()
    @FocusState private var isAmountFocused: Bool
    
    // Do wyboru daty
    @State private var isDatePickerVisible = false
    
    var body: some View {
        NavigationView {
            Form {
                // Sekcja podstawowych informacji
                Section(header: Text("Informacje podstawowe")) {
                    // Opis wydatku
                    TextField("Opis wydatku", text: $viewModel.description)
                    
                    // Kwota
                    HStack {
                        Text("Kwota")
                        Spacer()
                        TextField("0.00", text: $viewModel.amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($isAmountFocused)
                        
                        Text(viewModel.currency)
                            .foregroundColor(.secondary)
                    }
                    
                    // Kto zapłacił
                    Picker("Kto zapłacił", selection: $viewModel.paidByUserId) {
                        ForEach(viewModel.availableMembers, id: \.id) { member in
                            Text(member.displayName).tag(member.id)
                        }
                    }
                    
                    // Data
                    Button(action: {
                        isDatePickerVisible.toggle()
                    }) {
                        HStack {
                            Text("Data")
                            Spacer()
                            Text(viewModel.formattedDate)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if isDatePickerVisible {
                        DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .labelsHidden()
                    }
                    
                    // Kategoria
                    Picker("Kategoria", selection: $viewModel.category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { category in
                            Label(category.displayName, systemImage: category.icon).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Sekcja podziału kosztów
                Section(header: Text("Podział kosztów")) {
                    Picker("Sposób podziału", selection: $viewModel.splitType) {
                        ForEach(SplitType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    // Lista osób do podziału
                    ForEach(viewModel.splits.indices, id: \.self) { index in
                        if index < viewModel.availableMembers.count {
                            HStack {
                                Text(viewModel.availableMembers[index].displayName)
                                
                                Spacer()
                                
                                // Różne pola w zależności od typu podziału
                                if viewModel.splitType == .equal {
                                    // Dla równego podziału tylko włączamy/wyłączamy udział
                                    Toggle("", isOn: $viewModel.splits[index].isIncluded)
                                        .labelsHidden()
                                } else if viewModel.splitType == .percentage {
                                    // Dla podziału procentowego
                                    TextField("0", text: $viewModel.splits[index].percentageText)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 50)
                                    
                                    Text("%")
                                        .foregroundColor(.secondary)
                                } else if viewModel.splitType == .exact {
                                    // Dla dokładnych kwot
                                    TextField("0.00", text: $viewModel.splits[index].amountText)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 70)
                                    
                                    Text(viewModel.currency)
                                        .foregroundColor(.secondary)
                                } else if viewModel.splitType == .shares {
                                    // Dla udziałów
                                    Stepper("\(viewModel.splits[index].shares)", value: $viewModel.splits[index].shares, in: 0...100)
                                }
                            }
                        }
                    }
                    
                    // Informacja o sumie podziału
                    if viewModel.splitType != .equal {
                        HStack {
                            Text("Suma")
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            if viewModel.splitType == .percentage {
                                Text("\(viewModel.totalPercentage, specifier: "%.1f")%")
                                    .foregroundColor(viewModel.isPercentageValid ? .green : .red)
                            } else if viewModel.splitType == .exact {
                                Text("\(viewModel.totalSplitAmount, specifier: "%.2f") \(viewModel.currency)")
                                    .foregroundColor(viewModel.isAmountValid ? .green : .red)
                            } else if viewModel.splitType == .shares {
                                Text("\(viewModel.totalShares) udziałów")
                            }
                        }
                    }
                }
                
                // Sekcja przycisków akcji
                Section {
                    Button(action: {
                        if viewModel.validateExpense() {
                            viewModel.createExpense(groupId: groupId) { success in
                                if success {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }
                    }) {
                        Text("Dodaj wydatek")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(viewModel.isLoading || !viewModel.canSubmit)
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Nowy wydatek")
            .navigationBarItems(leading: Button("Anuluj") {
                presentationMode.wrappedValue.dismiss()
            })
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
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                        .edgesIgnoringSafeArea(.all)
                }
            }
            .onAppear {
                viewModel.loadGroupMembers(groupId: groupId)
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Gotowe") {
                        isAmountFocused = false
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct CreateExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        CreateExpenseView(groupId: "sample_group_id")
    }
}
