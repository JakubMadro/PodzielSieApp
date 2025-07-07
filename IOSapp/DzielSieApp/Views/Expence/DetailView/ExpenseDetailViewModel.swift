//
//  ExpenseDetailViewModel.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//


import Foundation
import Combine

class ExpenseDetailViewModel: ObservableObject {
    @Published var expense: Expense?
    @Published var isLoading = false
    @Published var error: String?
    @Published var shouldNavigateBack = false
    @Published var comments: [ExpenseComment] = []
    
    private let expenseService: ExpenseServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(expenseService: ExpenseServiceProtocol = ExpenseService()) {
        self.expenseService = expenseService
    }
    
    func loadExpenseDetails(expenseId: String) {
        isLoading = true
        error = nil
        
        expenseService.getExpenseDetails(expenseId: expenseId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] expense in
                self?.expense = expense
                // Zapisujemy komentarze w osobnej opublikowanej właściwości
                self?.comments = expense.comments ?? []
            }
            .store(in: &cancellables)
    }
    
    func deleteExpense() {
        guard let expense = expense else { return }
        
        isLoading = true
        error = nil
        
        expenseService.deleteExpense(expenseId: expense.id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] success in
                if success {
                    self?.shouldNavigateBack = true
                    // Możemy też wysłać powiadomienie o usunięciu wydatku
                    NotificationCenter.default.post(name: NSNotification.Name("ExpenseDeleted"), object: nil)
                } else {
                    self?.error = "Nie udało się usunąć wydatku"
                }
            }
            .store(in: &cancellables)
    }
    
    func addComment(text: String) {
        guard let expense = expense else { return }
        
        isLoading = true
        error = nil
        
        expenseService.addComment(expenseId: expense.id, text: text)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] comment in
                // Dodajemy komentarz do naszej lokalnej tablicy komentarzy
                self?.comments.append(comment)
            }
            .store(in: &cancellables)
    }
    
    func settleSplit(splitId: String) {
        // Tutaj dodaj implementację oznaczania splitu jako rozliczonego
        // W prawdziwej implementacji wysłałbyś żądanie do API
        guard let expense = expense else { return }
        
        isLoading = true
        error = nil
        
        let updateData: [String: Any] = [
            "splitId": splitId,
            "settled": true
        ]
        
        expenseService.updateExpense(expenseId: expense.id, updateData: updateData)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] updatedExpense in
                self?.expense = updatedExpense
                // Możemy też wysłać powiadomienie o aktualizacji wydatku
                NotificationCenter.default.post(name: NSNotification.Name("ExpenseUpdated"), object: nil)
            }
            .store(in: &cancellables)
    }
    
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            self.error = apiError.localizedDescription
        } else {
            self.error = "Nieznany błąd: \(error.localizedDescription)"
        }
    }
}
