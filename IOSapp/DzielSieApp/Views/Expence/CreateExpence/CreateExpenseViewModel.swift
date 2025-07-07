//
//  CreateExpenseViewModel.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//

import Foundation
import Combine

/// ViewModel zarządzający tworzeniem nowego wydatku w grupie
/// Obsługuje walidację, podział kosztów i komunikację z API
class CreateExpenseViewModel: ObservableObject {
    // MARK: - Published properties (obserwowalne przez UI)
    /// Opis wydatku
    @Published var description: String = ""
    
    /// Kwota wydatku jako tekst (dla TextField)
    @Published var amountText: String = ""
    
    /// Waluta wydatku
    @Published var currency: String = "PLN"
    
    /// ID użytkownika, który zapłacił
    @Published var paidByUserId: String = ""
    
    /// Data wydatku
    @Published var date: Date = Date()
    
    /// Kategoria wydatku
    @Published var category: ExpenseCategory = .other
    
    /// Typ podziału kosztów
    @Published var splitType: SplitType = .equal
    
    /// Lista elementów podziału dla każdego użytkownika
    @Published var splits: [SplitItem] = []
    
    /// Czy operacja jest w trakcie
    @Published var isLoading: Bool = false
    
    /// Komunikat błędu
    @Published var error: String?
    
    /// Lista dostępnych członków grupy
    @Published var availableMembers: [GroupUser] = []
    
    // MARK: - Private properties
    private let expenseService: ExpenseServiceProtocol
    private let groupsService: GroupsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed properties (wyliczane dynamicznie)
    /// Konwertuje tekst kwoty na wartość Double
    var amount: Double {
        return Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    
    /// Formatuje datę do wyświetlenia
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    /// Suma wszystkich procentów w podziale procentowym
    var totalPercentage: Double {
        return splits.reduce(0) { $0 + ($1.percentage ?? 0) }
    }
    
    /// Suma wszystkich kwot w podziale dokładnym
    var totalSplitAmount: Double {
        return splits.reduce(0) { $0 + ($1.amount ?? 0) }
    }
    
    /// Całkowita liczba udziałów
    var totalShares: Int {
        return splits.reduce(0) { $0 + $1.shares }
    }
    
    /// Sprawdza czy suma procentów wynosi 100% (z tolerancją)
    var isPercentageValid: Bool {
        return abs(totalPercentage - 100) < 0.1 // Z tolerancją dla błędów zaokrąglenia
    }
    
    /// Sprawdza czy suma kwot równa się całkowitej kwocie (z tolerancją)
    var isAmountValid: Bool {
        return abs(totalSplitAmount - amount) < 0.01 // Z tolerancją dla błędów zaokrąglenia
    }
    
    /// Sprawdza czy formularz może być wysłany
    var canSubmit: Bool {
        return !description.isEmpty && amount > 0 && !paidByUserId.isEmpty && areAllSplitsValid()
    }
    
    // MARK: - Initialization
    /// Inicjalizator z możliwością wstrzyknięcia zależności
    /// - Parameters:
    ///   - expenseService: Serwis wydatków
    ///   - groupsService: Serwis grup
    init(expenseService: ExpenseServiceProtocol = ExpenseService(), groupsService: GroupsServiceProtocol = GroupsService()) {
        self.expenseService = expenseService
        self.groupsService = groupsService
        
        // Ustaw domyślnie bieżącego użytkownika jako płatnika
        if let currentUserId = AppState.shared.currentUser?.id {
            self.paidByUserId = currentUserId
        }
    }
    
    // MARK: - Public methods
    func loadGroupMembers(groupId: String) {
        isLoading = true
        error = nil
        
        groupsService.fetchGroupDetails(groupId: groupId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.isLoading = false
                if case .failure(let error) = result {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] group in
                // Pobierz użytkowników z grupy
                let users = group.members.map { $0.user }
                self?.availableMembers = users
                
                // Ustaw domyślną walutę grupy
                self?.currency = group.defaultCurrency
                
                // Inicjalizuj podział kosztów
                self?.initializeSplits(users: users)
                
                // Ustaw bieżącego użytkownika jako płatnika, jeśli jest członkiem grupy
                if let currentUserId = AppState.shared.currentUser?.id,
                   users.contains(where: { $0.id == currentUserId }) {
                    self?.paidByUserId = currentUserId
                } else if let firstUserId = users.first?.id {
                    // Jeśli bieżący użytkownik nie jest członkiem, ustaw pierwszego użytkownika z listy
                    self?.paidByUserId = firstUserId
                }
            }
            .store(in: &cancellables)
    }
    
    func validateExpense() -> Bool {
        // Sprawdź podstawowe walidacje
        if description.isEmpty {
            error = "Opis wydatku jest wymagany"
            return false
        }
        
        if amount <= 0 {
            error = "Kwota musi być większa od zera"
            return false
        }
        
        if paidByUserId.isEmpty {
            error = "Wybierz osobę, która zapłaciła"
            return false
        }
        
        // Sprawdź walidacje związane z podziałem kosztów
        switch splitType {
        case .equal:
            // Sprawdź, czy przynajmniej jedna osoba jest wybrana
            if !splits.contains(where: { $0.isIncluded }) {
                error = "Wybierz przynajmniej jedną osobę do podziału kosztów"
                return false
            }
        case .percentage:
            // Sprawdź, czy suma procentów wynosi 100%
            if !isPercentageValid {
                error = "Suma procentów musi wynosić 100%"
                return false
            }
        case .exact:
            // Sprawdź, czy suma kwot wynosi całkowitą kwotę wydatku
            if !isAmountValid {
                error = "Suma kwot podziału musi być równa kwocie całkowitej"
                return false
            }
        case .shares:
            // Sprawdź, czy przynajmniej jedna osoba ma udziały
            if totalShares <= 0 {
                error = "Przydziel przynajmniej jeden udział"
                return false
            }
        }
        
        return true
    }
    
    func createExpense(groupId: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        error = nil
        
        // Przygotowanie danych do utworzenia wydatku
        let expenseData = prepareExpenseData(groupId: groupId)
        
        expenseService.createExpense(expenseData)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.isLoading = false
                if case .failure(let error) = result {
                    self?.handleError(error)
                    completion(false)
                }
            } receiveValue: { _ in
                completion(true)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private methods
    private func initializeSplits(users: [GroupUser]) {
        // Inicjalizacja tablicy podziałów kosztów
        splits = users.map { user in
            SplitItem(
                userId: user.id,
                isIncluded: true,  // Domyślnie wszyscy są włączeni dla podziału po równo
                amount: 0,
                percentage: 0,
                shares: 1  // Domyślnie każdy ma 1 udział
            )
        }
    }
    
    private func prepareExpenseData(groupId: String) -> ExpenseCreateData {
        // Przygotowanie tablicy podziałów w zależności od typu podziału
        var splitItems: [ExpenseSplitCreateData] = []
        
        switch splitType {
        case .equal:
            // Dla podziału po równo
            let includedSplits = splits.filter { $0.isIncluded }
            let splitAmount = amount / Double(includedSplits.count)
            
            splitItems = includedSplits.map { split in
                ExpenseSplitCreateData(
                    user: split.userId,
                    amount: splitAmount,
                    percentage: nil,
                    shares: nil
                )
            }
            
        case .percentage:
            // Dla podziału procentowego
            splitItems = splits.compactMap { split in
                guard let percentage = split.percentage, percentage > 0 else { return nil }
                
                return ExpenseSplitCreateData(
                    user: split.userId,
                    amount: amount * percentage / 100.0,
                    percentage: percentage,
                    shares: nil
                )
            }
            
        case .exact:
            // Dla dokładnych kwot
            splitItems = splits.compactMap { split in
                guard let splitAmount = split.amount, splitAmount > 0 else { return nil }
                
                return ExpenseSplitCreateData(
                    user: split.userId,
                    amount: splitAmount,
                    percentage: nil,
                    shares: nil
                )
            }
            
        case .shares:
            // Dla udziałów
            let totalShares = self.totalShares
            guard totalShares > 0 else { return ExpenseCreateData(group: groupId, description: description, amount: amount, currency: currency, paidBy: paidByUserId, date: date, category: category.rawValue, splitType: splitType.rawValue, splits: [], flags: nil) }
            
            splitItems = splits.map { split in
                let splitAmount = amount * Double(split.shares) / Double(totalShares)
                
                return ExpenseSplitCreateData(
                    user: split.userId,
                    amount: splitAmount,
                    percentage: nil,
                    shares: split.shares
                )
            }
        }
        
        // Utworzenie danych wydatku
        return ExpenseCreateData(
            group: groupId,
            description: description,
            amount: amount,
            currency: currency,
            paidBy: paidByUserId,
            date: date,
            category: category.rawValue,
            splitType: splitType.rawValue,
            splits: splitItems,
            flags: nil
        )
    }
    
    private func areAllSplitsValid() -> Bool {
        switch splitType {
        case .equal:
            return splits.contains(where: { $0.isIncluded })
        case .percentage:
            return isPercentageValid
        case .exact:
            return isAmountValid
        case .shares:
            return totalShares > 0
        }
    }
    
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            self.error = apiError.localizedDescription
        } else {
            self.error = "Nieznany błąd: \(error.localizedDescription)"
        }
    }
}

// MARK: - Helper Models
class SplitItem: Identifiable, ObservableObject {
    let id = UUID().uuidString
    let userId: String
    
    @Published var isIncluded: Bool
    @Published var amountText: String = "0"
    @Published var percentageText: String = "0"
    @Published var shares: Int
    
    var amount: Double? {
        return Double(amountText.replacingOccurrences(of: ",", with: "."))
    }
    
    var percentage: Double? {
        return Double(percentageText.replacingOccurrences(of: ",", with: "."))
    }
    
    init(userId: String, isIncluded: Bool, amount: Double?, percentage: Double?, shares: Int) {
        self.userId = userId
        self.isIncluded = isIncluded
        self.shares = shares
        
        if let amount = amount {
            self.amountText = String(format: "%.2f", amount)
        }
        
        if let percentage = percentage {
            self.percentageText = String(format: "%.1f", percentage)
        }
    }
}
