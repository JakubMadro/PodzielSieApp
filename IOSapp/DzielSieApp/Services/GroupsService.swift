//
//  GroupsService.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 06/04/2025.
//

import Foundation
import Combine

protocol GroupsServiceProtocol {
    func fetchGroups() -> AnyPublisher<[Group], Error>
    func fetchGroupDetails(groupId: String) -> AnyPublisher<Group, Error>
    func fetchUserBalance(groupId: String) -> AnyPublisher<UserBalanceDetails, Error>
    func createGroup(name: String, description: String?, defaultCurrency: String?) -> AnyPublisher<Group, Error>
    func updateGroup(groupId: String, name: String?, description: String?, defaultCurrency: String?) -> AnyPublisher<Group, Error>
    func addMember(groupId: String, email: String, role: String?) -> AnyPublisher<Group, Error>
    func removeMember(groupId: String, userId: String) -> AnyPublisher<Group, Error>
    func updateMemberRole(groupId: String, userId: String, role: String) -> AnyPublisher<Group, Error>
    func archiveGroup(groupId: String, archive: Bool) -> AnyPublisher<Group, Error>
    func deleteGroup(groupId: String) -> AnyPublisher<Bool, Error>
}

final class GroupsService: GroupsServiceProtocol {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    func fetchGroups() -> AnyPublisher<[Group], Error> {
        return networkService.request(.getGroups)
            .map { (response: GroupsResponse) -> [Group] in
                return response.groups
            }
            .eraseToAnyPublisher()
    }
    
    func fetchGroupDetails(groupId: String) -> AnyPublisher<Group, Error> {
        return networkService.request(.getGroupDetails(groupId: groupId))
            .map { (response: GroupResponse) -> Group in
                return response.group
            }
            .eraseToAnyPublisher()
    }
    
    func createGroup(name: String, description: String?, defaultCurrency: String?) -> AnyPublisher<Group, Error> {
        // Wydrukuj dane grupy, które będą wysłane
        print("Creating group: name=\(name), description=\(description ?? "nil"), currency=\(defaultCurrency ?? "PLN")")
        
        return networkService.request(.createGroup(name: name, description: description, defaultCurrency: defaultCurrency))
            .map { (response: GroupResponse) -> Group in
                return response.group
            }
            .eraseToAnyPublisher()
    }
    
    func updateGroup(groupId: String, name: String?, description: String?, defaultCurrency: String?) -> AnyPublisher<Group, Error> {
        return networkService.request(.updateGroup(groupId: groupId, name: name, description: description, defaultCurrency: defaultCurrency))
            .map { (response: GroupResponse) -> Group in
                return response.group
            }
            .eraseToAnyPublisher()
    }
    
    func addMember(groupId: String, email: String, role: String? = nil) -> AnyPublisher<Group, Error> {
        // Wydrukuj dane, które będą wysłane
        print("Adding member to group: groupId=\(groupId), email=\(email), role=\(role ?? "default")")
        
        return networkService.request(.addGroupMember(groupId: groupId, email: email, role: role))
            .map { (response: GroupResponse) -> Group in
                return response.group
            }
            .eraseToAnyPublisher()
    }
    
    func removeMember(groupId: String, userId: String) -> AnyPublisher<Group, Error> {
        return networkService.request(.removeGroupMember(groupId: groupId, userId: userId))
            .map { (response: GroupResponse) -> Group in
                return response.group
            }
            .eraseToAnyPublisher()
    }
    
    func updateMemberRole(groupId: String, userId: String, role: String) -> AnyPublisher<Group, Error> {
        return networkService.request(.updateMemberRole(groupId: groupId, userId: userId, role: role))
            .map { (response: GroupResponse) -> Group in
                return response.group
            }
            .eraseToAnyPublisher()
    }
    
    func archiveGroup(groupId: String, archive: Bool) -> AnyPublisher<Group, Error> {
        return networkService.request(.archiveGroup(groupId: groupId, archive: archive))
            .map { (response: GroupResponse) -> Group in
                return response.group
            }
            .eraseToAnyPublisher()
    }
    
    func deleteGroup(groupId: String) -> AnyPublisher<Bool, Error> {
        struct DeleteResponse: Codable {
            let success: Bool
            let message: String
        }
        
        return networkService.request(.deleteGroup(groupId: groupId))
            .map { (response: DeleteResponse) -> Bool in
                return response.success
            }
            .eraseToAnyPublisher()
    }
    func fetchUserBalance(groupId: String) -> AnyPublisher<UserBalanceDetails, Error> {
        return networkService.request(.getUserBalance(groupId: groupId))
            .map { (response: UserBalanceResponse) -> UserBalanceDetails in
                return response.balance
            }
            .eraseToAnyPublisher()
    }
}
