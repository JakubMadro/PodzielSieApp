//
//  SettlementsViewModel.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//


import Foundation
import Combine

class SettlementsViewModel: ObservableObject {
    @Published var pendingSettlements: [Settlement] = []
    @Published var settlementHistory: [Settlement] = []
    @Published var userGroups: [Group] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let settlementService: SettlementServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(settlementService: SettlementServiceProtocol = SettlementService()) {
        self.settlementService = settlementService
    }
    
    func loadData() {
        isLoading = true
        error = nil
        
        // Pobierz tylko oczekujące na starcie
        loadPendingSettlements()
    }
    
    func loadUserGroups() {
        let groupsService = GroupsService()
        
        groupsService.fetchGroups()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] groups in
                self?.userGroups = groups.filter { !$0.isArchived }
            }
            .store(in: &cancellables)
    }
    
    func loadPendingSettlements() {
        settlementService.getPendingSettlements()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
                self?.checkLoadingComplete()
            } receiveValue: { [weak self] response in
                self?.pendingSettlements = response.settlements.sorted { $0.date > $1.date }
            }
            .store(in: &cancellables)
    }
    
    func loadCompletedSettlements() {
        // Sprawdź czy już pobrane
        guard settlementHistory.isEmpty else { return }
        
        settlementService.getCompletedSettlements()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
                self?.isLoading = false
            } receiveValue: { [weak self] response in
                self?.settlementHistory = response.settlements.sorted { $0.date > $1.date }
            }
            .store(in: &cancellables)
    }
    
    private func checkLoadingComplete() {
        // Sprawdź czy oba żądania są zakończone
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isLoading = false
        }
    }
    
    // Metoda obsługi błędów
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            self.error = apiError.localizedDescription
        } else {
            self.error = "Nieznany błąd: \(error.localizedDescription)"
        }
    }
}
