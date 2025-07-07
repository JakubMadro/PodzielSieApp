//
//  GroupSelectionViewModel.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 06/04/2025.
//


import Foundation
import Combine

class GroupSelectionViewModel: ObservableObject {
    @Published var groups: [Group] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let groupsService: GroupsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(groupsService: GroupsServiceProtocol = GroupsService()) {
        self.groupsService = groupsService
    }
    
    func loadGroups(completion: ((Group?) -> Void)? = nil) {
        isLoading = true
        error = nil
        
        groupsService.fetchGroups()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.isLoading = false
                
                if case .failure(let apiError) = result {
                    self?.error = apiError.localizedDescription
                }
            } receiveValue: { [weak self] fetchedGroups in
                guard let self = self else { return }
                
                if fetchedGroups.isEmpty {
                    self.error = "Nie masz jeszcze żadnych grup. Najpierw utwórz grupę."
                    completion?(nil)
                } else {
                    self.groups = fetchedGroups
                    completion?(fetchedGroups.first)
                }
            }
            .store(in: &cancellables)
    }
}