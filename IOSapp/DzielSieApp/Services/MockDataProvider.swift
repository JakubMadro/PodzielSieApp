////
////  MockDataProvider.swift
////  DzielSieApp
////
////  Created by Kuba Mądro on 06/04/2025.
////
//
//import Foundation
//import Combine
//
//#if DEBUG
//// Klasa do dostarczania przykładowych danych podczas developmentu
//class MockDataProvider {
//    static func getMockGroups() -> [Group] {
//        let now = Date()
//        let calendar = Calendar.current
//        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
//        let lastWeek = calendar.date(byAdding: .day, value: -7, to: now)!
//        
//        let currentUser = AppState.shared.currentUser
//        let currentUserId = currentUser?.id ?? "user123"
//        
//        return [
//            Group(
//                id: "1",
//                name: "Wyjazd w góry",
//                description: "Wspólny wyjazd w Tatry w czerwcu 2025",
//                defaultCurrency: "PLN",
//                members: [
//                    GroupMember(
//                        id: "m1",
//                        user: GroupUser(id: currentUserId, firstName: "Jan", lastName: "Kowalski", email: "jan@example.com", avatar: nil),
//                        role: "admin",
//                        joined: lastWeek
//                    ),
//                    GroupMember(
//                        id: "m2",
//                        user: GroupUser(id: "user456", firstName: "Anna", lastName: "Nowak", email: "anna@example.com", avatar: nil),
//                        role: "member",
//                        joined: lastWeek
//                    ),
//                    GroupMember(
//                        id: "m3",
//                        user: GroupUser(id: "user789", firstName: "Piotr", lastName: "Wiśniewski", email: "piotr@example.com", avatar: nil),
//                        role: "member",
//                        joined: lastWeek
//                    )
//                ],
//                isArchived: false,
//                createdAt: lastWeek,
//                updatedAt: yesterday,
//                userBalance: -125.50
//            ),
//            Group(
//                id: "2",
//                name: "Wspólne mieszkanie",
//                description: "Wydatki związane z mieszkaniem",
//                defaultCurrency: "PLN",
//                members: [
//                    GroupMember(
//                        id: "m1",
//                        user: GroupUser(id: currentUserId, firstName: "Jan", lastName: "Kowalski", email: "jan@example.com", avatar: nil),
//                        role: "member",
//                        joined: lastWeek
//                    ),
//                    GroupMember(
//                        id: "m2",
//                        user: GroupUser(id: "user456", firstName: "Anna", lastName: "Nowak", email: "anna@example.com", avatar: nil),
//                        role: "admin",
//                        joined: lastWeek
//                    )
//                ],
//                isArchived: false,
//                createdAt: lastWeek,
//                updatedAt: now,
//                userBalance: 324.75
//            ),
//            Group(
//                id: "3",
//                name: "Rodzina",
//                description: "Wydatki rodzinne",
//                defaultCurrency: "PLN",
//                members: [
//                    GroupMember(
//                        id: "m1",
//                        user: GroupUser(id: currentUserId, firstName: "Jan", lastName: "Kowalski", email: "jan@example.com", avatar: nil),
//                        role: "admin",
//                        joined: lastWeek
//                    ),
//                    GroupMember(
//                        id: "m4",
//                        user: GroupUser(id: "user101", firstName: "Maria", lastName: "Kowalska", email: "maria@example.com", avatar: nil),
//                        role: "member",
//                        joined: lastWeek
//                    ),
//                    GroupMember(
//                        id: "m5",
//                        user: GroupUser(id: "user102", firstName: "Tomasz", lastName: "Kowalski", email: "tomasz@example.com", avatar: nil),
//                        role: "member",
//                        joined: lastWeek
//                    )
//                ],
//                isArchived: true,
//                createdAt: lastWeek,
//                updatedAt: now,
//                userBalance: 0.0
//            )
//        ]
//    }
//}
//
//// Rozszerzenia dla podglądu w SwiftUI
//extension Group {
//    static var mockGroup: Group {
//        MockDataProvider.getMockGroups()[0]
//    }
//    
//    static var mockGroups: [Group] {
//        MockDataProvider.getMockGroups()
//    }
//}
//
//// Mock dla serwisu grup do testowania i podglądu
//class MockGroupsService: GroupsServiceProtocol {
//    func fetchGroups() -> AnyPublisher<[Group], Error> {
//        return Just(MockDataProvider.getMockGroups())
//            .setFailureType(to: Error.self)
//            .eraseToAnyPublisher()
//    }
//    
//    func fetchGroupDetails(groupId: String) -> AnyPublisher<Group, Error> {
//        guard let group = MockDataProvider.getMockGroups().first(where: { $0.id == groupId }) else {
//            return Fail(error: APIError.serverError(message: "Grupa nie znaleziona"))
//                .eraseToAnyPublisher()
//        }
//        
//        return Just(group)
//            .setFailureType(to: Error.self)
//            .eraseToAnyPublisher()
//    }
//    
//    func createGroup(name: String, description: String?, defaultCurrency: String?) -> AnyPublisher<Group, Error> {
//        let now = Date()
//        let currentUser = AppState.shared.currentUser
//        let userId = currentUser?.id ?? "user123"
//        
//        let newGroup = Group(
//            id: "new\(Int.random(in: 1000...9999))",
//            name: name,
//            description: description,
//            defaultCurrency: defaultCurrency ?? "PLN",
//            members: [
//                GroupMember(
//                    id: "m1",
//                    user: GroupUser(
//                        id: userId,
//                        firstName: currentUser?.firstName ?? "Jan",
//                        lastName: currentUser?.lastName ?? "Kowalski",
//                        email: currentUser?.email ?? "jan@example.com",
//                        avatar: nil
//                    ),
//                    role: "admin",
//                    joined: now
//                )
//            ],
//            isArchived: false,
//            createdAt: now,
//            updatedAt: now,
//            userBalance: 0.0
//        )
//        
//        return Just(newGroup)
//            .setFailureType(to: Error.self)
//            .eraseToAnyPublisher()
//    }
//    
//    func updateGroup(groupId: String, name: String?, description: String?, defaultCurrency: String?) -> AnyPublisher<Group, Error> {
//        guard var group = MockDataProvider.getMockGroups().first(where: { $0.id == groupId }) else {
//            return Fail(error: APIError.serverError(message: "Grupa nie znaleziona"))
//                .eraseToAnyPublisher()
//        }
//        
//        // W rzeczywistej implementacji nie powinniśmy tak modyfikować struct
//        // ale to tylko dla celów podglądu
//        var updatedGroup = group
//        
//        if let name = name {
//            // Tutaj tylko dla celów demonstracyjnych - w rzeczywistości będziemy tworzyć nowy obiekt
//            updatedGroup = Group(
//                id: group.id,
//                name: name,
//                description: description ?? group.description,
//                defaultCurrency: defaultCurrency ?? group.defaultCurrency,
//                members: group.members,
//                isArchived: group.isArchived,
//                createdAt: group.createdAt,
//                updatedAt: Date(),
//                userBalance: group.userBalance
//            )
//        }
//        
//        return Just(updatedGroup)
//            .setFailureType(to: Error.self)
//            .eraseToAnyPublisher()
//    }
//    
//    func addMember(groupId: String, email: String, role: String?) -> AnyPublisher<Group, Error> {
//        guard var group = MockDataProvider.getMockGroups().first(where: { $0.id == groupId }) else {
//            return Fail(error: APIError.serverError(message: "Grupa nie znaleziona"))
//                .eraseToAnyPublisher()
//        }
//        
//        // Sprawdź, czy użytkownik o takim emailu już istnieje
//        if group.members.contains(where: { $0.user.email == email }) {
//            return Fail(error: APIError.serverError(message: "Użytkownik jest już członkiem tej grupy"))
//                .eraseToAnyPublisher()
//        }
//        
//        let newMember = GroupMember(
//            id: "new\(Int.random(in: 1000...9999))",
//            user: GroupUser(
//                id: "new\(Int.random(in: 1000...9999))",
//                firstName: "Nowy",
//                lastName: "Użytkownik",
//                email: email,
//                avatar: nil
//            ),
//            role: role ?? "member",
//            joined: Date()
//        )
//        
//        var updatedMembers = group.members
//        updatedMembers.append(newMember)
//        
//        let updatedGroup = Group(
//            id: group.id,
//            name: group.name,
//            description: group.description,
//            defaultCurrency: group.defaultCurrency,
//            members: updatedMembers,
//            isArchived: group.isArchived,
//            createdAt: group.createdAt,
//            updatedAt: Date(),
//            userBalance: group.userBalance
//        )
//        
//        return Just(updatedGroup)
//            .setFailureType(to: Error.self)
//            .eraseToAnyPublisher()
//    }
//    
//    func removeMember(groupId: String, userId: String) -> AnyPublisher<Group, Error> {
//        guard var group = MockDataProvider.getMockGroups().first(where: { $0.id == groupId }) else {
//            return Fail(error: APIError.serverError(message: "Grupa nie znaleziona"))
//                .eraseToAnyPublisher()
//        }
//        
//        let updatedMembers = group.members.filter { $0.user.id != userId }
//        
//        let updatedGroup = Group(
//            id: group.id,
//            name: group.name,
//            description: group.description,
//            defaultCurrency: group.defaultCurrency,
//            members: updatedMembers,
//            isArchived: group.isArchived,
//            createdAt: group.createdAt,
//            updatedAt: Date(),
//            userBalance: group.userBalance
//        )
//        
//        return Just(updatedGroup)
//            .setFailureType(to: Error.self)
//            .eraseToAnyPublisher()
//    }
//    
//    func updateMemberRole(groupId: String, userId: String, role: String) -> AnyPublisher<Group, Error> {
//        guard var group = MockDataProvider.getMockGroups().first(where: { $0.id == groupId }) else {
//            return Fail(error: APIError.serverError(message: "Grupa nie znaleziona"))
//                .eraseToAnyPublisher()
//        }
//        
//        var updatedMembers = group.members
//        if let index = updatedMembers.firstIndex(where: { $0.user.id == userId }) {
//            updatedMembers[index] = GroupMember(
//                id: updatedMembers[index].id,
//                user: updatedMembers[index].user,
//                role: role,
//                joined: updatedMembers[index].joined
//            )
//        }
//        
//        let updatedGroup = Group(
//            id: group.id,
//            name: group.name,
//            description: group.description,
//            defaultCurrency: group.defaultCurrency,
//            members: updatedMembers,
//            isArchived: group.isArchived,
//            createdAt: group.createdAt,
//            updatedAt: Date(),
//            userBalance: group.userBalance
//        )
//        
//        return Just(updatedGroup)
//            .setFailureType(to: Error.self)
//            .eraseToAnyPublisher()
//    }
//    
//    func archiveGroup(groupId: String, archive: Bool) -> AnyPublisher<Group, Error> {
//        guard var group = MockDataProvider.getMockGroups().first(where: { $0.id == groupId }) else {
//            return Fail(error: APIError.serverError(message: "Grupa nie znaleziona"))
//                .eraseToAnyPublisher()
//        }
//        
//        let updatedGroup = Group(
//            id: group.id,
//            name: group.name,
//            description: group.description,
//            defaultCurrency: group.defaultCurrency,
//            members: group.members,
//            isArchived: archive,
//            createdAt: group.createdAt,
//            updatedAt: Date(),
//            userBalance: group.userBalance
//        )
//        
//        return Just(updatedGroup)
//            .setFailureType(to: Error.self)
//            .eraseToAnyPublisher()
//    }
//    
//    func deleteGroup(groupId: String) -> AnyPublisher<Bool, Error> {
//        return Just(true)
//            .setFailureType(to: Error.self)
//            .eraseToAnyPublisher()
//    }
//}
//#endif
