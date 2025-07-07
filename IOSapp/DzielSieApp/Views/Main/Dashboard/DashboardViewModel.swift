//
//  DashboardViewModel.swift
//  DzielSieApp
//
//  Created by Claude on 06/04/2025.
//

import Foundation
import Combine

class DashboardViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let dashboardService: DashboardServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(dashboardService: DashboardServiceProtocol = DashboardService()) {
        self.dashboardService = dashboardService
    }
    
    func fetchRecentActivities() {
        isLoading = true
        error = nil
        
        dashboardService.fetchRecentActivities(limit: 10)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] activities in
                self?.activities = activities
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
    
    // Funkcja dostarczająca przykładowe dane do podglądu
    static func getMockActivities() -> [Activity] {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now)!
        
        return [
            Activity(
                id: "1",
                type: .newExpense,
                title: "Dodałeś wydatek: Zakupy spożywcze",
                subtitle: "Wspólne mieszkanie • dzisiaj",
                amount: 125.50,
                currency: "PLN",
                date: now,
                iconName: "cart.fill",
                groupId: "1",
                expenseId: "1"
            ),
            Activity(
                id: "2",
                type: .newExpense,
                title: "Anna dodała: Kino",
                subtitle: "Wyjazd w góry • wczoraj",
                amount: 72.00,
                currency: "PLN",
                date: yesterday,
                iconName: "ticket.fill",
                groupId: "2",
                expenseId: "2"
            ),
            Activity(
                id: "3",
                type: .addedToGroup,
                title: "Dołączyłeś do grupy Wyjazd nad morze",
                subtitle: "Zaproszenie od Piotra • 2 dni temu",
                amount: nil,
                currency: "PLN",
                date: twoDaysAgo,
                iconName: "person.3.fill",
                groupId: "3",
                expenseId: nil
            )
        ]
    }
}
