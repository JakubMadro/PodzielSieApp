//
//  AddMemberViewModel.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//

import Foundation
import Combine

protocol AddMemberViewModelDelegate: AnyObject {
    func memberAdded(to group: Group)
}

class AddMemberViewModel: ObservableObject {
    @Published var memberEmail = ""
    @Published var memberRole = "member"
    @Published var isLoading = false
    @Published var error: String?
    
    weak var delegate: AddMemberViewModelDelegate?
    private let group: Group
    private let groupsService: GroupsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(group: Group, groupsService: GroupsServiceProtocol = GroupsService()) {
        self.group = group
        self.groupsService = groupsService
    }
    
    func addMember() {
        guard !memberEmail.isEmpty else {
            error = "Email nowego członka jest wymagany"
            return
        }
        
        isLoading = true
        error = nil
        
        groupsService.addMember(
            groupId: group.id,
            email: memberEmail,
            role: memberRole
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            self?.isLoading = false
            if case .failure(let error) = completion {
                self?.handleError(error)
            }
        } receiveValue: { [weak self] updatedGroup in
            print("Member added to group: \(updatedGroup)")
            self?.delegate?.memberAdded(to: updatedGroup)
            NotificationCenter.default.post(name: NSNotification.Name("GroupUpdated"), object: nil)
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
