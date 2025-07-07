//
//  ExpenseDetailView.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//


import SwiftUI

struct ExpenseDetailView: View {
    let expenseId: String
    @StateObject private var viewModel = ExpenseDetailViewModel()
    @State private var showConfirmationDialog = false
    @State private var showSettlementOptions = false
    @State private var selectedSplitId: String?
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let expense = viewModel.expense {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Nagłówek wydatku
                        ExpenseHeaderView(expense: expense)
                        
                        Divider()
                        
                        // Szczegóły wydatku
                        ExpenseDetailsSection(expense: expense)
                        
                        // Podział kosztów
                        ExpenseSplitsSection(expense: expense)
                        
                        // Komentarze
                        if !viewModel.comments.isEmpty {
                            ExpenseCommentsSection(comments: viewModel.comments)
                        }
                        
                        // Przyciski akcji (jeśli to twój wydatek)
                        if isUserExpense(expense) {
                            ExpenseActionsView(
                                onEdit: {
                                    // TODO: Implementacja edycji
                                },
                                onDelete: {
                                    showConfirmationDialog = true
                                }
                            )
                        }
                        
                        // Przyciski do rozliczenia (dla niewyrównanych splitów)
                        ForEach(expense.splits.filter { !$0.settled && $0.user.id != expense.paidBy.id }) { split in
                            SettleSplitView(
                                expense: expense,
                                split: split,
                                onSettle: {
                                    selectedSplitId = split.id
                                    showSettlementOptions = true
                                }
                            )
                        }
                    }
                    .padding()
                }
                .confirmationDialog(
                    "Czy na pewno chcesz usunąć ten wydatek?",
                    isPresented: $showConfirmationDialog,
                    titleVisibility: .visible
                ) {
                    Button("Usuń", role: .destructive) {
                        viewModel.deleteExpense()
                    }
                    Button("Anuluj", role: .cancel) {}
                }
                .actionSheet(isPresented: $showSettlementOptions) {
                    guard let split = getSplitById(selectedSplitId) else {
                        return ActionSheet(title: Text("Błąd"), message: Text("Nie można znaleźć wybranego splitu"), buttons: [.cancel()])
                    }
                    
                    return ActionSheet(
                        title: Text("Rozlicz z użytkownikiem"),
                        message: Text("Kwota: \(formatAmount(split.amount, currency: expense.currency))"),
                        buttons: [
                            .default(Text("Oznacz jako opłacone gotówką")) {
                                // Tu dodać logikę oznaczania jako rozliczone
                                markSplitAsSettled(splitId: split.id)
                            },
                            .default(Text("Utwórz rozliczenie")) {
                                // Tu dodać przejście do tworzenia rozliczenia
                                createSettlementForSplit(split: split)
                            },
                            .cancel(Text("Anuluj"))
                        ]
                    )
                }
            } else {
                Text("Nie można załadować szczegółów wydatku")
            }
        }
        .navigationTitle("Szczegóły wydatku")
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
            viewModel.loadExpenseDetails(expenseId: expenseId)
        }
    }
    
    // Sprawdza, czy zalogowany użytkownik jest właścicielem wydatku
    private func isUserExpense(_ expense: Expense) -> Bool {
        return expense.paidBy.id == AppState.shared.currentUser?.id
    }
    
    // Pobiera split po ID
    private func getSplitById(_ id: String?) -> ExpenseSplit? {
        guard let id = id, let expense = viewModel.expense else { return nil }
        return expense.splits.first { $0.id == id }
    }
    
    // Oznacza split jako rozliczony
    private func markSplitAsSettled(splitId: String) {
        // Tu dodać logikę oznaczania splitu jako rozliczonego
        // W prawdziwej implementacji wysłałbyś żądanie do API
        viewModel.settleSplit(splitId: splitId)
    }
    
    // Tworzy rozliczenie dla splitu
    private func createSettlementForSplit(split: ExpenseSplit) {
        // Tu dodać logikę tworzenia rozliczenia na podstawie splitu
        // W prawdziwej implementacji przeszedłbyś do ekranu tworzenia rozliczenia
        print("Tworzenie rozliczenia dla splitu \(split.id)")
    }
    
    // Formatuje kwotę
    private func formatAmount(_ amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
    }
    
    // Formatuje datę
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Komponenty pomocnicze

struct ExpenseHeaderView: View {
    let expense: Expense
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Ikona kategorii
                ZStack {
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: expense.category.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.description)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(formatAmount(expense.amount, currency: expense.currency))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(formatDate(expense.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
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
        formatter.dateStyle = .long
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

struct ExpenseDetailsSection: View {
    let expense: Expense
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Szczegóły")
                .font(.headline)
            
            VStack(spacing: 12) {
                ExpenseDetailRow(title: "Osoba płacąca", value: "\(expense.paidBy.firstName) \(expense.paidBy.lastName)")
                ExpenseDetailRow(title: "Kategoria", value: expense.category.displayName)
                ExpenseDetailRow(title: "Sposób podziału", value: expense.splitType.displayName)
                
                if let receipt = expense.receipt, !receipt.isEmpty {
                    HStack {
                        Text("Paragon")
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: {
                            // Otwórz podgląd paragonu
                        }) {
                            Text("Zobacz paragon")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }
}

struct ExpenseDetailRow: View {
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

struct ExpenseSplitsSection: View {
    let expense: Expense
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Podział kosztów")
                .font(.headline)
            
            ForEach(expense.splits) { split in
                HStack {
                    // Inicjały użytkownika
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Text(getInitials(firstName: split.user.firstName, lastName: split.user.lastName))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    
                    // Dane użytkownika
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(split.user.firstName) \(split.user.lastName)")
                            .font(.system(size: 16, weight: .medium))
                        
                        if let percentage = split.percentage, percentage > 0 {
                            Text("\(percentage, specifier: "%.1f")%")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else if let shares = split.shares, shares > 0 {
                            Text("\(shares) udziałów")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    // Kwota
                    Text(formatAmount(split.amount, currency: expense.currency))
                        .font(.headline)
                    
                    // Status rozliczenia
                    if split.settled {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                    }
                }
                .padding(.vertical, 8)
                
                if split.id != expense.splits.last?.id {
                    Divider()
                }
            }
        }
    }
    
    private func getInitials(firstName: String, lastName: String) -> String {
        let firstInitial = firstName.prefix(1).uppercased()
        let lastInitial = lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }
    
    private func formatAmount(_ amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
    }
}

struct ExpenseCommentsSection: View {
    let comments: [ExpenseComment]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Komentarze")
                .font(.headline)
            
            ForEach(comments) { comment in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        // Inicjały użytkownika
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 30, height: 30)
                            
                            Text(getInitials(firstName: comment.user.firstName, lastName: comment.user.lastName))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.gray)
                        }
                        
                        Text("\(comment.user.firstName) \(comment.user.lastName)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(formatDate(comment.createdAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(comment.text)
                        .font(.body)
                        .padding(.leading, 40)
                }
                .padding(.vertical, 8)
                
                if comment.id != comments.last?.id {
                    Divider()
                }
            }
        }
    }
    
    private func getInitials(firstName: String, lastName: String) -> String {
        let firstInitial = firstName.prefix(1).uppercased()
        let lastInitial = lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ExpenseActionsView: View {
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onEdit) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edytuj")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Button(action: onDelete) {
                HStack {
                    Image(systemName: "trash")
                    Text("Usuń")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding(.top, 10)
    }
}

// Nowy komponent do rozliczeń pojedynczego splitu
struct SettleSplitView: View {
    let expense: Expense
    let split: ExpenseSplit
    let onSettle: () -> Void
    
    var body: some View {
        Button(action: onSettle) {
            HStack {
                Image(systemName: "checkmark.circle")
                Text("Oznacz jako rozliczone: \(split.user.firstName)")
                Spacer()
                Text(formatAmount(split.amount, currency: expense.currency))
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
    
    private func formatAmount(_ amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
    }
}
