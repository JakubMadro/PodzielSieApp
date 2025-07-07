//
//  Group.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 06/04/2025.
//


import Foundation

struct Group: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let defaultCurrency: String
    let members: [GroupMember]
    let isArchived: Bool
    let createdAt: Date
    let updatedAt: Date
    var userBalance: Double?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case description
        case defaultCurrency
        case members
        case isArchived
        case createdAt
        case updatedAt
        case userBalance
    }
    
    var isOwner: Bool {
        guard let currentUserId = AppState.shared.currentUser?.id else { return false }
        return isAdmin(userId: currentUserId)
    }
    
    var memberCount: Int {
        return members.count
    }
    
    func isAdmin(userId: String) -> Bool {
        return members.first(where: { $0.user.id == userId })?.role == "admin"
    }
}

struct GroupMember: Identifiable, Codable {
    let id: String
    let user: GroupUser
    let role: String
    let joined: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user
        case role
        case joined
    }
}

struct GroupUser: Identifiable, Codable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let avatar: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName
        case lastName
        case email
        case avatar
    }
    
    var initials: String {
        let firstNameInitial = firstName.prefix(1).uppercased()
        let lastNameInitial = lastName.prefix(1).uppercased()
        return "\(firstNameInitial)\(lastNameInitial)"
    }
    
    var displayName: String {
        return "\(firstName) \(lastName)"
    }
}

// Struktury odpowiedzi z API
struct GroupsResponse: Codable {
    let success: Bool
    let groups: [Group]
}

struct GroupResponse: Codable {
    let success: Bool
    let group: Group
}

