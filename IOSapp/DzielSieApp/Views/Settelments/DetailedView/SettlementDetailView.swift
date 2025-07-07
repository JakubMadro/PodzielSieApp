//
//  SettlementDetailView.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//


import SwiftUI

struct SettlementDetailView: View {
    let settlementId: String
    @StateObject private var viewModel = SettlementDetailViewModel()
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let settlement = viewModel.settlement {
                ScrollView {
                    VStack(spacing: 20) {
                        // Nagłówek z kwotą
                        AmountHeaderView(settlement: settlement)
                        
                        // Status
                        StatusView(status: settlement.status)
                        
                        Divider()
                        
                        // Szczegóły rozliczenia
                        SettlementDetailsSection(settlement: settlement)
                        
                        Divider()
                        
                        // Informacje o osobach
                        UsersSection(settlement: settlement)
                        
                        // Przyciski rozliczenia (tylko dla pending settlements)
                        if settlement.status == .pending {
                            VStack(spacing: 12) {
                                if isUserPayer(settlement) {
                                    Button(action: {
                                        viewModel.settleAsPayment(settlementId: settlement.id)
                                    }) {
                                        HStack {
                                            Image(systemName: "creditcard.fill")
                                            Text("Oznacz jako zapłacone")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                    }
                                }
                                
                                if isUserReceiver(settlement) {
                                    Button(action: {
                                        viewModel.settleAsReceived(settlementId: settlement.id)
                                    }) {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                            Text("Potwierdź otrzymanie")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(.top, 20)
                        }
                    }
                    .padding()
                }
            } else {
                Text("Nie można załadować szczegółów rozliczenia")
            }
        }
        .navigationTitle("Szczegóły rozliczenia")
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
        .onAppear {
            viewModel.loadSettlementDetails(settlementId: settlementId)
        }
    }
    
    // Sprawdza, czy zalogowany użytkownik jest płatnikiem
    private func isUserPayer(_ settlement: Settlement) -> Bool {
        return settlement.payer.id == AppState.shared.currentUser?.id
    }
    
    // Sprawdza, czy zalogowany użytkownik jest odbiorcą
    private func isUserReceiver(_ settlement: Settlement) -> Bool {
        return settlement.receiver.id == AppState.shared.currentUser?.id
    }
}

// MARK: - Komponenty widoku szczegółów

struct AmountHeaderView: View {
    let settlement: Settlement
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Kwota rozliczenia")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(formatAmount(settlement.amount, currency: settlement.currency))
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.primary)
            
            Text(formatDate(settlement.date))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func formatAmount(_ amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct StatusView: View {
    let status: SettlementStatus
    
    var body: some View {
        HStack {
            Image(systemName: status.icon)
                .foregroundColor(statusColor)
            
            Text(status.displayName)
                .font(.headline)
                .foregroundColor(statusColor)
                
            Spacer()
        }
        .padding()
        .background(statusColor.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch status.color {
        case "green":
            return .green
        case "yellow":
            return .yellow
        case "red":
            return .red
        default:
            return .gray
        }
    }
}

struct SettlementDetailsSection: View {
    let settlement: Settlement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Szczegóły")
                .font(.headline)
            
            VStack(spacing: 12) {
                SettlementDetailRow(title: "Grupa", value: settlement.group)
                
                if let method = settlement.paymentMethod {
                    SettlementDetailRow(title: "Metoda płatności", value: method.displayName)
                }
                
                if let reference = settlement.paymentReference, !reference.isEmpty {
                    SettlementDetailRow(title: "Referencja płatności", value: reference)
                }
                
                SettlementDetailRow(title: "Data utworzenia", value: formatDate(settlement.createdAt))
                
                if settlement.status == .completed {
                    SettlementDetailRow(title: "Data rozliczenia", value: formatDate(settlement.updatedAt))
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct SettlementDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.primary)
        }
    }
}

struct UsersSection: View {
    let settlement: Settlement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Osoby")
                .font(.headline)
            
            HStack(spacing: 20) {
                // Od kogo
                VStack(spacing: 10) {
                    VStack(spacing: 4) {
                        Text("Od")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        UserAvatarView(user: settlement.payer)
                            .frame(width: 60, height: 60)
                    }
                    
                    Text("\(settlement.payer.firstName) \(settlement.payer.lastName)")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
                
                // Strzałka
                VStack {
                    Image(systemName: "arrow.right")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                
                // Do kogo
                VStack(spacing: 10) {
                    VStack(spacing: 4) {
                        Text("Do")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        UserAvatarView(user: settlement.receiver)
                            .frame(width: 60, height: 60)
                    }
                    
                    Text("\(settlement.receiver.firstName) \(settlement.receiver.lastName)")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}
