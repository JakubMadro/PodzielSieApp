//
//  SettlementConfirmationView.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 08/04/2025.
//

import SwiftUI
import Combine

struct SettlementConfirmationView: View {
    let suggestion: SettlementSuggestion
    let groupId: String
    let currency: String
    let onComplete: () -> Void
    
    @State private var selectedMethod: PaymentMethod = .manual
    @State private var paymentReference: String = ""
    @State private var isLoading = false
    @State private var error: String?
    @Environment(\.presentationMode) var presentationMode
    
    // Używamy @State dla cancellables
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Szczegóły rozliczenia")) {
                    HStack {
                        Text("Od")
                        Spacer()
                        Text("\(suggestion.payer.firstName) \(suggestion.payer.lastName)")
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Text("Do")
                        Spacer()
                        Text("\(suggestion.receiver.firstName) \(suggestion.receiver.lastName)")
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Text("Kwota")
                        Spacer()
                        Text(formatAmount(suggestion.amount))
                            .foregroundColor(.primary)
                            .fontWeight(.bold)
                    }
                }
                
                Section(header: Text("Metoda płatności")) {
                    Picker("Metoda", selection: $selectedMethod) {
                        ForEach([PaymentMethod.manual, .blik, .paypal, .other], id: \.self) { method in
                            HStack {
                                Image(systemName: method.icon)
                                Text(method.displayName)
                            }.tag(method)
                        }
                    }
                    .pickerStyle(InlinePickerStyle())
                }
                
                Section(header: Text("Referencja płatności (opcjonalnie)")) {
                    TextField("Numer referencyjny, identyfikator przelewu itp.", text: $paymentReference)
                }
                
                Section {
                    Button(action: confirmSettlement) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Potwierdź rozliczenie")
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .navigationTitle("Rozliczenie")
            .navigationBarItems(leading: Button("Anuluj") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: Binding<Bool>(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )) {
                Alert(
                    title: Text("Błąd"),
                    message: Text(error ?? "Wystąpił nieznany błąd"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func confirmSettlement() {
        isLoading = true
        error = nil
        
        let createService = CreateSettlementService()
        
        createService.createSettlement(
            groupId: groupId,
            toUserId: suggestion.receiver.id,
            amount: suggestion.amount,
            currency: currency,
            paymentMethod: selectedMethod,
            paymentReference: paymentReference.isEmpty ? nil : paymentReference
        )
        .receive(on: DispatchQueue.main)
        .sink { completion in
            if case .failure(let error) = completion {
                isLoading = false
                if let apiError = error as? APIError {
                    self.error = apiError.localizedDescription
                } else {
                    self.error = "Nieznany błąd: \(error.localizedDescription)"
                }
            }
        } receiveValue: { _ in
            isLoading = false
            onComplete()
        }
        .store(in: &cancellables)
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: abs(amount))) ?? "\(abs(amount)) \(currency)"
    }
}
