//
//  GroupsViewModel.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//

import Foundation
import Combine

class GroupsViewModel: ObservableObject, CreateGroupViewModelDelegate, AddMemberViewModelDelegate {
    @Published var groups: [Group] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showCreateGroupView = false
    @Published var showAddMemberView = false
    @Published var showConfirmationDialog = false
    @Published var selectedGroup: Group?
    
    private let groupsService: GroupsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(groupsService: GroupsServiceProtocol = GroupsService()) {
        self.groupsService = groupsService
        
        // Nasłuchuj powiadomień o zmianach w grupach
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshGroups),
            name: NSNotification.Name("GroupCreated"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshGroups),
            name: NSNotification.Name("GroupUpdated"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func refreshGroups() {
        fetchGroups()
    }
    
    // MARK: - Delegate Methods
    
    func groupCreated(_ group: Group) {
        DispatchQueue.main.async {
            self.groups.append(group)
            self.showCreateGroupView = false
        }
    }
    
    func memberAdded(to group: Group) {
        DispatchQueue.main.async {
            if let index = self.groups.firstIndex(where: { $0.id == group.id }) {
                self.groups[index] = group
            }
            self.showAddMemberView = false
        }
    }
    
    // MARK: - Group Operations
    
    func fetchGroups() {
        isLoading = true
        error = nil
        
        groupsService.fetchGroups()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] groups in
                self?.groups = groups
            }
            .store(in: &cancellables)
    }
    
    func archiveGroup(groupId: String, archive: Bool) {
        isLoading = true
        error = nil
        
        groupsService.archiveGroup(groupId: groupId, archive: archive)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] updatedGroup in
                if let index = self?.groups.firstIndex(where: { $0.id == updatedGroup.id }) {
                    self?.groups[index] = updatedGroup
                }
            }
            .store(in: &cancellables)
    }
    
    func deleteGroup(groupId: String) {
        isLoading = true
        error = nil
        
        groupsService.deleteGroup(groupId: groupId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                    self?.showConfirmationDialog = false
                }
            } receiveValue: { [weak self] success in
                if success {
                    self?.groups.removeAll { $0.id == groupId }
                    self?.showConfirmationDialog = false
                }
            }
            .store(in: &cancellables)
    }
    
    func selectGroup(_ group: Group) {
        selectedGroup = group
        showCreateGroupView = true
    }
    
    func selectGroupForAddingMember(_ group: Group) {
        selectedGroup = group
        showAddMemberView = true
    }
    
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            self.error = apiError.localizedDescription
            
            if case .unauthorized = apiError {
                AppState.shared.logout()
            }
        } else {
            self.error = "Nieznany błąd: \(error.localizedDescription)"
        }
    }
}
