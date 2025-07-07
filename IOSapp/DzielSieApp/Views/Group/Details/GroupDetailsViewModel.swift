//
//  GroupDetailsViewModel.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 06/04/2025.
//

import Foundation
import Combine
import UIKit

class GroupDetailsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var group: Group?
    @Published var isLoading = false
    @Published var error: String?
    @Published var navigateBack = false
    @Published var showAddExpenseSheet = false
    
    // MARK: - Properties
    var groupId: String = ""
    
    // MARK: - Private Properties
    private let groupsService: GroupsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(groupsService: GroupsServiceProtocol = GroupsService()) {
        self.groupsService = groupsService
    }
    
    // MARK: - Public Methods
    
    func fetchGroupDetails() {
        isLoading = true
        error = nil
        
        groupsService.fetchGroupDetails(groupId: groupId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] group in
                self?.group = group
            }
            .store(in: &cancellables)
    }
    
    func toggleArchive() {
        guard let group = self.group else { return }
        
        isLoading = true
        error = nil
        
        groupsService.archiveGroup(groupId: group.id, archive: !group.isArchived)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] updatedGroup in
                self?.group = updatedGroup
            }
            .store(in: &cancellables)
    }
    
    func deleteGroup() {
        isLoading = true
        error = nil
        
        groupsService.deleteGroup(groupId: groupId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] success in
                if success {
                    // Nawiguj z powrotem do listy grup
                    self?.navigateBack = true
                } else {
                    self?.error = "Nie udało się usunąć grupy"
                }
            }
            .store(in: &cancellables)
    }
    
    func removeMember(_ userId: String) {
        isLoading = true
        error = nil
        
        groupsService.removeMember(groupId: groupId, userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] updatedGroup in
                self?.group = updatedGroup
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            self.error = apiError.localizedDescription
            
            // Jeśli błąd jest związany z autoryzacją, możemy wylogować użytkownika
            if case .unauthorized = apiError {
                AppState.shared.logout()
            }
        } else {
            self.error = "Nieznany błąd: \(error.localizedDescription)"
        }
    }
}
