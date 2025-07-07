//
//  ExpensesViewModel.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//


import Foundation
import Combine

class ExpensesViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var expensesByGroup: [String: [Expense]] = [:]
    @Published var isLoading = false
    @Published var error: String?
    
    private let groupsService: GroupsServiceProtocol
    private let expenseService: ExpenseServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(groupsService: GroupsServiceProtocol = GroupsService(), 
         expenseService: ExpenseServiceProtocol = ExpenseService()) {
        self.groupsService = groupsService
        self.expenseService = expenseService
    }
    
    func loadUserExpenses() {
        isLoading = true
        error = nil
        expensesByGroup = [:]
        
        fetchGroupsAndExpenses()
    }
    
    private func fetchGroupsAndExpenses() {
        groupsService.fetchGroups()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.isLoading = false
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] groups in
                guard let self = self, !groups.isEmpty else {
                    self?.isLoading = false
                    return
                }
                
                self.fetchExpensesForGroups(groups)
            }
            .store(in: &cancellables)
    }
    
    private func fetchExpensesForGroups(_ groups: [Group]) {
        var allExpenses: [Expense] = []
        var expensesByGroup: [String: [Expense]] = [:]
        let dispatchGroup = DispatchGroup()
        
        for group in groups {
            dispatchGroup.enter()
            
            expenseService.getGroupExpenses(groupId: group.id, page: 1, limit: 10)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    if case .failure = completion {
                        // Ignorujemy błędy poszczególnych grup
                    }
                    dispatchGroup.leave()
                } receiveValue: { response in
                    let groupExpenses = response.expenses
                    if !groupExpenses.isEmpty {
                        expensesByGroup[group.name] = groupExpenses
                        allExpenses.append(contentsOf: groupExpenses)
                    }
                }
                .store(in: &cancellables)
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.isLoading = false
            self?.expenses = allExpenses.sorted(by: { $0.date > $1.date })
            self?.expensesByGroup = expensesByGroup
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