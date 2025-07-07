//
//  GroupBalanceView.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//

import SwiftUI
import Combine

struct GroupBalanceView: View {
    let groupId: String
    let groupName: String
    
    @StateObject private var viewModel = GroupBalanceViewModel()
    @State private var showSettlementConfirmation = false
    @State private var selectedSuggestion: SettlementSuggestion?
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Sekcja bilansu
                        balanceSection
                        
                        Divider()
                        
                        // Sekcja sugestii rozliczeń
                        if !viewModel.settlementSuggestions.isEmpty {
                            settlementSuggestionsSection
                        }
                        
                        Divider()
                        
                        // Sekcja szczegółowych bilansów
                        detailedBalancesSection
                    }
                    .padding()
                }
                .refreshable {
                    viewModel.loadGroupBalances(groupId: groupId)
                }
            }
        }
        .navigationTitle("Bilans grupy")
        .navigationBarItems(trailing:
            HStack {
                Button(action: {
                    viewModel.refreshGroupBalances(groupId: groupId)
                }) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                
                NavigationLink(destination: CreateSettlementView(groupId: groupId, groupName: groupName)) {
                    Image(systemName: "plus")
                }
            }
        )
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
        .sheet(isPresented: $showSettlementConfirmation) {
            if let suggestion = selectedSuggestion {
                SettlementConfirmationView(
                    suggestion: suggestion,
                    groupId: groupId,
                    currency: viewModel.currency,
                    onComplete: {
                        showSettlementConfirmation = false
                        viewModel.loadGroupBalances(groupId: groupId)
                    }
                )
            }
        }
        .onAppear {
            viewModel.loadGroupBalances(groupId: groupId)
        }
    }
    
    // Sekcja podsumowania bilansu
    private var balanceSection: some View {
        VStack(spacing: 16) {
            Text("Twój bilans w grupie")
                .font(.headline)
            
            let myBalance = viewModel.userBalances.first {
                $0.id == AppState.shared.currentUser?.id
            }?.balance ?? 0
            
            Text(formatBalance(myBalance))
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(balanceColor(myBalance))
            
            Text(balanceDescription(myBalance))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // Sekcja sugestii rozliczeń
    private var settlementSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sugestie rozliczeń")
                .font(.headline)
            
            ForEach(Array(viewModel.settlementSuggestions.enumerated()), id: \.offset) { index, suggestion in
                if isUserInvolved(in: suggestion) {
                    Button(action: {
                        selectedSuggestion = suggestion
                        showSettlementConfirmation = true
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                // Od kogo
                                Text(suggestion.payer.firstName)
                                    .fontWeight(.medium)
                                
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.blue)
                                
                                // Do kogo
                                Text(suggestion.receiver.firstName)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                // Kwota
                                Text(formatAmount(suggestion.amount))
                                    .fontWeight(.bold)
                            }
                            
                            if isUserPayer(in: suggestion) {
                                Text("Zapłać, aby rozliczyć swój dług")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Oczekuj zapłaty")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // Sekcja szczegółowych bilansów
    private var detailedBalancesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Szczegółowe bilanse")
                .font(.headline)
            
            ForEach(viewModel.userBalances) { balance in
                HStack {
                    // Inicjały użytkownika
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Text(getInitials(firstName: balance.firstName, lastName: balance.lastName))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    
                    // Dane użytkownika
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(balance.firstName) \(balance.lastName)")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text(balance.email)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Bilans
                    Text(formatAmount(balance.balance))
                        .fontWeight(.bold)
                        .foregroundColor(balanceColor(balance.balance))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
            }
        }
    }
    
    // Helper functions
    private func isUserInvolved(in suggestion: SettlementSuggestion) -> Bool {
        guard let currentUserId = AppState.shared.currentUser?.id else { return false }
        return suggestion.payer.id == currentUserId || suggestion.receiver.id == currentUserId
    }
    
    private func isUserPayer(in suggestion: SettlementSuggestion) -> Bool {
        guard let currentUserId = AppState.shared.currentUser?.id else { return false }
        return suggestion.payer.id == currentUserId
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = viewModel.currency
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: abs(amount))) ?? "\(abs(amount)) \(viewModel.currency)"
    }
    
    private func formatBalance(_ balance: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = viewModel.currency
        formatter.maximumFractionDigits = 2
        
        let formattedValue = formatter.string(from: NSNumber(value: abs(balance))) ?? "\(abs(balance)) \(viewModel.currency)"
        
        if balance < 0 {
            return "-\(formattedValue)"
        } else if balance > 0 {
            return "+\(formattedValue)"
        } else {
            return formattedValue
        }
    }
    
    private func balanceColor(_ balance: Double) -> Color {
        if balance < 0 {
            return .red
        } else if balance > 0 {
            return .green
        } else {
            return .primary
        }
    }
    
    private func balanceDescription(_ balance: Double) -> String {
        if balance < 0 {
            return "Musisz oddać \(formatAmount(abs(balance)))"
        } else if balance > 0 {
            return "Inni są Ci winni \(formatAmount(balance))"
        } else {
            return "Twój bilans jest wyrównany"
        }
    }
    
    private func getInitials(firstName: String, lastName: String) -> String {
        let firstInitial = firstName.prefix(1).uppercased()
        let lastInitial = lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }
}
