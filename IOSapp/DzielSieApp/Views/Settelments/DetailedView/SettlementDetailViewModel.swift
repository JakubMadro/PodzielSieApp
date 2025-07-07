//
//  SettlementDetailViewModel.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//


import Foundation
import Combine

class SettlementDetailViewModel: ObservableObject {
    @Published var settlement: Settlement?
    @Published var isLoading = false
    @Published var error: String?
    @Published var isCompleted = false
    
    private let settlementService: SettlementServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(settlementService: SettlementServiceProtocol = SettlementService()) {
        self.settlementService = settlementService
    }
    
    func loadSettlementDetails(settlementId: String) {
        isLoading = true
        error = nil
        
        settlementService.getSettlementDetails(settlementId: settlementId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] settlement in
                self?.settlement = settlement
                self?.isCompleted = settlement.status == .completed
            }
            .store(in: &cancellables)
    }
    
    func settleDebt(paymentMethod: PaymentMethod, reference: String?) {
        guard let settlement = settlement, settlement.status == .pending else { return }
        
        isLoading = true
        error = nil
        
        settlementService.settleDebt(
            settlementId: settlement.id,
            paymentMethod: paymentMethod,
            paymentReference: reference
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            self?.isLoading = false
            if case .failure(let error) = completion {
                self?.handleError(error)
            }
        } receiveValue: { [weak self] updatedSettlement in
            self?.settlement = updatedSettlement
            self?.isCompleted = updatedSettlement.status == .completed
            
            // Powiadomienie o zakończeniu rozliczenia
            NotificationCenter.default.post(name: NSNotification.Name("SettlementCompleted"), object: nil)
        }
        .store(in: &cancellables)
    }
    
    func settleAsPayment(settlementId: String) {
        // Oznacza rozliczenie jako zapłacone przez płatnika
        settleDebt(paymentMethod: .manual, reference: nil)
    }
    
    func settleAsReceived(settlementId: String) {
        // Potwierdza otrzymanie przez odbiorcę
        settleDebt(paymentMethod: .manual, reference: nil)
    }
    
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            self.error = apiError.localizedDescription
        } else {
            self.error = "Nieznany błąd: \(error.localizedDescription)"
        }
    }
}
