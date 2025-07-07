//
//  GroupBalanceViewModel.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//


import Foundation
import Combine

class GroupBalanceViewModel: ObservableObject {
    @Published var userBalances: [UserBalance] = []
    @Published var settlementSuggestions: [SettlementSuggestion] = []
    @Published var userSettlements: [Settlement] = []
    @Published var otherSettlements: [Settlement] = []
    @Published var currency: String = "PLN"
    @Published var userNetBalance: Double = 0
    @Published var isLoading = false
    @Published var error: String?
    
    private let settlementService: SettlementServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(settlementService: SettlementServiceProtocol = SettlementService()) {
        self.settlementService = settlementService
    }
    
    func loadGroupBalances(groupId: String) {
        isLoading = true
        error = nil
        
        settlementService.getGroupBalances(groupId: groupId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] response in
                // Jeśli backend zwraca nową strukturę z settlements
                if !response.userSettlements.isEmpty || !response.otherSettlements.isEmpty {
                    self?.userSettlements = response.userSettlements
                    self?.otherSettlements = response.otherSettlements
                    
                    if let summary = response.summary {
                        self?.currency = summary.currency
                        self?.userNetBalance = summary.userNetBalance
                    }
                    
                    // Konwertuj settlements na user balances
                    self?.convertSettlementsToUserBalances()
                    self?.generateSettlementSuggestionsFromSettlements()
                }
                // Jeśli backend zwraca starą strukturę (fallback)
                else if let balances = response.balances {
                    self?.userBalances = balances
                    self?.currency = response.currency ?? "PLN"
                    self?.settlementSuggestions = response.settlementSuggestions ?? []
                }
            }
            .store(in: &cancellables)
    }
    
    func refreshGroupBalances(groupId: String) {
        loadGroupBalances(groupId: groupId)
    }
    
    private func convertSettlementsToUserBalances() {
        var balanceMap: [String: Double] = [:]
        var userInfoMap: [String: (firstName: String, lastName: String, email: String)] = [:]
        
        // Funkcja pomocnicza do dodawania użytkowników
        func addUserInfo(from user: User) {
            userInfoMap[user.id] = (
                firstName: user.firstName,
                lastName: user.lastName,
                email: user.email
            )
        }
        
        // Przetwórz user settlements
        for settlement in userSettlements {
            addUserInfo(from: settlement.payer)
            addUserInfo(from: settlement.receiver)
            
            balanceMap[settlement.payer.id, default: 0] -= settlement.amount
            balanceMap[settlement.receiver.id, default: 0] += settlement.amount
        }
        
        // Przetwórz other settlements
        for settlement in otherSettlements {
            addUserInfo(from: settlement.payer)
            addUserInfo(from: settlement.receiver)
            
            balanceMap[settlement.payer.id, default: 0] -= settlement.amount
            balanceMap[settlement.receiver.id, default: 0] += settlement.amount
        }
        
        // Konwertuj na UserBalance
        userBalances = balanceMap.compactMap { (userId, balance) in
            guard let userInfo = userInfoMap[userId] else { return nil }
            return UserBalance(
                id: userId,
                firstName: userInfo.firstName,
                lastName: userInfo.lastName,
                email: userInfo.email,
                balance: balance
            )
        }
    }
    
    private func generateSettlementSuggestionsFromSettlements() {
        settlementSuggestions = userSettlements.compactMap { settlement in
            SettlementSuggestion(
                fromUser: UserInfo(
                    id: settlement.payer.id,
                    name: "\(settlement.payer.firstName) \(settlement.payer.lastName)",
                    email: settlement.payer.email
                ),
                toUser: UserInfo(
                    id: settlement.receiver.id,
                    name: "\(settlement.receiver.firstName) \(settlement.receiver.lastName)",
                    email: settlement.receiver.email
                ),
                amount: settlement.amount
            )
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
