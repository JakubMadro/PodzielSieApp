//
//  CreateGroupViewModel.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//

import Foundation
import Combine

protocol CreateGroupViewModelDelegate: AnyObject {
    func groupCreated(_ group: Group)
}

class CreateGroupViewModel: ObservableObject {
    @Published var groupName = ""
    @Published var groupDescription = ""
    @Published var defaultCurrency = "PLN"
    @Published var isLoading = false
    @Published var error: String?
    
    weak var delegate: CreateGroupViewModelDelegate?
    private let groupsService: GroupsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(groupsService: GroupsServiceProtocol = GroupsService()) {
        self.groupsService = groupsService
    }
    
    func createGroup() {
        guard !groupName.isEmpty else {
            error = "Nazwa grupy jest wymagana"
            return
        }
        
        isLoading = true
        error = nil
        
        groupsService.createGroup(
            name: groupName,
            description: groupDescription.isEmpty ? nil : groupDescription,
            defaultCurrency: defaultCurrency
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            self?.isLoading = false
            if case .failure(let error) = completion {
                self?.handleError(error)
            }
        } receiveValue: { [weak self] group in
            print("Group created: \(group)")
            self?.delegate?.groupCreated(group)
            NotificationCenter.default.post(name: NSNotification.Name("GroupCreated"), object: nil)
        }
        .store(in: &cancellables)
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
