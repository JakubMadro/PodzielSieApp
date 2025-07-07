//
//  ExpensesView.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//


import SwiftUI

struct ExpensesView: View {
    @StateObject private var viewModel = ExpensesViewModel()
    @State private var selectedGroupId: String?
    @State private var showAddExpenseSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if viewModel.expenses.isEmpty {
                    emptyExpensesView
                } else {
                    expensesList
                }
            }
            .navigationTitle("Wydatki")
            .navigationBarItems(trailing: Button(action: {
                showGroupSelectionSheet()
            }) {
                Image(systemName: "plus")
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
            .sheet(isPresented: $showAddExpenseSheet) {
                if let groupId = selectedGroupId {
                    CreateExpenseView(groupId: groupId)
                }
            }
            .onAppear {
                viewModel.loadUserExpenses()
            }
            .refreshable {
                viewModel.loadUserExpenses()
            }
        }
    }
    
    private var emptyExpensesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.7))
            
            Text("Brak wydatków")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Nie masz jeszcze żadnych wydatków w swoich grupach.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                showGroupSelectionSheet()
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
    
    private var expensesList: some View {
        List {
            ForEach(viewModel.expensesByGroup.keys.sorted(), id: \.self) { groupName in
                if let groupExpenses = viewModel.expensesByGroup[groupName], !groupExpenses.isEmpty {
                    Section(header: Text(groupName)) {
                        ForEach(groupExpenses) { expense in
                            NavigationLink(destination: ExpenseDetailView(expenseId: expense.id)) {
                                ExpenseListItemView(expense: expense)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func showGroupSelectionSheet() {
        // Najpierw otwieramy selektor grup
        let selectionViewModel = GroupSelectionViewModel()
        selectionViewModel.loadGroups { group in
            if let group = group {
                self.selectedGroupId = group.id
                self.showAddExpenseSheet = true
            }
        }
    }
}

struct ExpenseListItemView: View {
    let expense: Expense
    
    var body: some View {
        HStack {
            // Ikona kategorii
            ZStack {
                Circle()
                    .fill(categoryColor)
                    .frame(width: 40, height: 40)
                
                Image(systemName: expense.category.icon)
                    .foregroundColor(.white)
            }
            
            // Informacje o wydatku
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.description)
                    .font(.headline)
                
                HStack {
                    Text("Zapłacone przez: \(expense.paidBy.firstName)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(formatDate(expense.date))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.leading, 8)
            
            Spacer()
            
            // Kwota
            Text(formatAmount(expense.amount, currency: expense.currency))
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
    }
    
    private var categoryColor: Color {
        switch expense.category {
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
    
    private func formatAmount(_ amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
    }
}