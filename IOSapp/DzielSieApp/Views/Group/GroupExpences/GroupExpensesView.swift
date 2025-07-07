//
//  GroupExpensesView.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//

import SwiftUI

struct GroupExpensesView: View {
    let groupId: String
    let groupName: String
    
    @StateObject private var viewModel = GroupExpensesViewModel()
    @State private var showAddExpenseSheet = false
    
    var body: some View {
        ZStack {
            if viewModel.expenses.isEmpty && !viewModel.isLoading {
                emptyExpensesView
            } else {
                expensesList
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .navigationTitle("Wydatki: \(groupName)")
        .navigationBarItems(trailing:
            Button(action: {
                showAddExpenseSheet = true
            }) {
                Image(systemName: "plus")
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
        .sheet(isPresented: $showAddExpenseSheet) {
            CreateExpenseView(groupId: groupId)
        }
        .onAppear {
            viewModel.loadExpenses(groupId: groupId)
        }
        .refreshable {
            viewModel.loadExpenses(groupId: groupId)
        }
    }
    
    // MARK: - Widok pustej listy wydatków
    private var emptyExpensesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.7))
            
            Text("Brak wydatków")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Dodaj pierwszy wydatek, aby rozpocząć dzielenie kosztów z przyjaciółmi.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                showAddExpenseSheet = true
            }) {
                Label("Dodaj pierwszy wydatek", systemImage: "plus")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
        }
    }
    
    // MARK: - Lista wydatków
    private var expensesList: some View {
        List {
            // Podsumowanie finansowe dla grupy
            Section(header: Text("Podsumowanie")) {
                HStack {
                    Text("Suma wydatków")
                    Spacer()
                    Text("\(viewModel.totalExpenses, specifier: "%.2f") \(viewModel.currency)")
                        .fontWeight(.bold)
                }
                
                // Szczegółowe wyświetlanie salda
                if let userBalance = viewModel.userBalance {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Twoje saldo")
                            Spacer()
                            Text(formatBalance(userBalance, currency: viewModel.currency))
                                .fontWeight(.bold)
                                .foregroundColor(balanceColor(userBalance))
                        }
                        
                        // Status salda
                        HStack {
                            Image(systemName: balanceIcon(userBalance))
                                .foregroundColor(balanceColor(userBalance))
                            Text(balanceStatusText(userBalance))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
                
                // Dodatkowe informacje o saldzie, jeśli dostępne
                if let balanceDetails = viewModel.userBalanceDetails {
                    DisclosureGroup("Szczegóły salda") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Zapłaciłeś łącznie:")
                                Spacer()
                                Text(balanceDetails.formattedAmountFromTotal(balanceDetails.totalPaid))
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Jesteś winien łącznie:")
                                Spacer()
                                Text(balanceDetails.formattedAmountFromTotal(balanceDetails.totalOwed))
                                    .fontWeight(.medium)
                            }
                            
                            Divider()
                            
                            if balanceDetails.amountToPay > 0 {
                                HStack {
                                    Text("Do zapłaty:")
                                    Spacer()
                                    Text(balanceDetails.formattedAmountToPay)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            if balanceDetails.amountToReceive > 0 {
                                HStack {
                                    Text("Do otrzymania:")
                                    Spacer()
                                    Text(balanceDetails.formattedAmountToReceive)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                            }
                            
                            // Aktywne rozliczenia
                            if !balanceDetails.activeSettlements.isEmpty {
                                Divider()
                                Text("Aktywne rozliczenia:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                ForEach(balanceDetails.activeSettlements, id: \.id) { settlement in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(settlement.typeDescription)
                                                .font(.caption2)
                                            Text(settlement.otherUser.name)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                        Spacer()
                                        Text(settlement.formattedAmount)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(settlement.type == "owes" ? .red : .green)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            // Lista wydatków
            Section(header: Text("Wydatki")) {
                ForEach(viewModel.expenses) { expense in
                    ExpenseRow(expense: expense)
                }
            }
            
            // Paginacja
            if viewModel.hasNextPage {
                Button(action: {
                    viewModel.loadMoreExpenses(groupId: groupId)
                }) {
                    Text("Załaduj więcej")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }
                .disabled(viewModel.isLoadingMore)
                .overlay {
                    if viewModel.isLoadingMore {
                        ProgressView()
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }

    // MARK: - Helper methods for balance formatting
    private func balanceColor(_ balance: Double) -> Color {
        if balance > 0 {
            return .green
        } else if balance < 0 {
            return .red
        } else {
            return .primary
        }
    }

    private func balanceStatusText(_ balance: Double) -> String {
        if balance > 0 {
            return "Na plusie"
        } else if balance < 0 {
            return "Do zapłaty"
        } else {
            return "Wyrównane"
        }
    }

    private func balanceIcon(_ balance: Double) -> String {
        if balance > 0 {
            return "arrow.up.circle.fill"
        } else if balance < 0 {
            return "arrow.down.circle.fill"
        } else {
            return "equal.circle.fill"
        }
    }
    
    // Formatter for balance
    private func formatBalance(_ balance: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        
        if let formattedValue = formatter.string(from: NSNumber(value: abs(balance))) {
            return balance < 0 ? "-\(formattedValue)" : (balance > 0 ? "+\(formattedValue)" : formattedValue)
        }
        
        return balance < 0 ? "-\(abs(balance)) \(currency)" : "+\(balance) \(currency)"
    }
}

// MARK: - Row for displaying expense
struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Category icon
                Circle()
                    .fill(categoryColor(expense.category))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: expense.category.icon)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.description)
                        .font(.headline)
                    
                    HStack(spacing: 4) {
                        Text("Zapłacone przez: \(expense.paidBy.firstName)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(formatDate(expense.date))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Text("\(expense.amount, specifier: "%.2f") \(expense.currency)")
                    .font(.system(size: 16, weight: .bold))
            }
        }
        .padding(.vertical, 4)
    }
    
    private func categoryColor(_ category: ExpenseCategory) -> Color {
        switch category {
        case .food:
            return .orange
        case .transport:
            return .blue
        case .accommodation:
            return .green
        case .entertainment:
            return .purple
        case .utilities:
            return .red
        case .other:
            return .gray
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}


// MARK: - Preview
struct GroupExpensesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GroupExpensesView(groupId: "sample_id", groupName: "Przykładowa grupa")
        }
    }
}
