//
//  GroupExpensesViewModel.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//

import Foundation
import Combine

class GroupExpensesViewModel: ObservableObject {
    // MARK: - Published properties
    @Published var expenses: [Expense] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: String?
    
    @Published var totalExpenses: Double = 0
    @Published var userBalance: Double?
    @Published var userBalanceDetails: UserBalanceDetails?
    @Published var currency: String = "PLN"
    
    // MARK: - Pagination properties
    private var currentPage = 1
    private var totalPages = 1
    
    var hasNextPage: Bool {
        return currentPage < totalPages
    }
    
    // MARK: - Private properties
    private let expenseService: ExpenseServiceProtocol
    private let groupsService: GroupsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(expenseService: ExpenseServiceProtocol = ExpenseService(), groupsService: GroupsServiceProtocol = GroupsService()) {
        self.expenseService = expenseService
        self.groupsService = groupsService
    }
    
    // MARK: - Public methods
    func loadExpenses(groupId: String) {
        isLoading = true
        error = nil
        currentPage = 1
        
        // Load group details and expenses
        let groupDetailsPublisher = loadGroupDetails(groupId: groupId)
        let expensesPublisher = loadExpensesData(groupId: groupId)
        
        // Combine both requests
        Publishers.Zip(groupDetailsPublisher, expensesPublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] (group, expenseResponse) in
                // Set group data
                self?.currency = group.defaultCurrency
                
                // Set expense data
                self?.expenses = expenseResponse.expenses
                self?.totalPages = expenseResponse.pagination.totalPages
                self?.calculateTotalExpense()
            }
            .store(in: &cancellables)
    }
    
    func loadMoreExpenses(groupId: String) {
        guard hasNextPage, !isLoadingMore else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        expenseService.getGroupExpenses(groupId: groupId, page: currentPage, limit: 20)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.isLoadingMore = false
                
                if case .failure(let error) = result {
                    self?.handleError(error)
                    self?.currentPage -= 1 // Revert page increment on failure
                }
            } receiveValue: { [weak self] response in
                self?.expenses.append(contentsOf: response.expenses)
                self?.totalPages = response.pagination.totalPages
                self?.calculateTotalExpense()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private methods
    private func loadGroupDetails(groupId: String) -> AnyPublisher<Group, Error> {
        return groupsService.fetchGroupDetails(groupId: groupId)
    }
    
    private func loadUserBalance(groupId: String) -> AnyPublisher<UserBalanceDetails, Error> {
        return groupsService.fetchUserBalance(groupId: groupId)
    }
    
    private func loadExpensesData(groupId: String) -> AnyPublisher<ExpensesResponse, Error> {
        return expenseService.getGroupExpenses(groupId: groupId, page: currentPage, limit: 20)
    }
    
    private func calculateTotalExpense() {
        totalExpenses = expenses.reduce(0) { $0 + $1.amount }
    }
    
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            self.error = apiError.localizedDescription
        } else {
            self.error = "Nieznany błąd: \(error.localizedDescription)"
        }
    }
}
