//
//  Group.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 06/04/2025.
//


import Foundation

/// Model reprezentujący grupę użytkowników do dzielenia wydatków
/// Identifiable - pozwala używać w SwiftUI List i ForEach
/// Codable - umożliwia serializację/deserializację JSON
struct Group: Identifiable, Codable {
    /// Unikalny identyfikator grupy
    let id: String
    
    /// Nazwa grupy
    let name: String
    
    /// Opcjonalny opis grupy
    let description: String?
    
    /// Domyślna waluta dla wydatków w grupie
    let defaultCurrency: String
    
    /// Lista członków grupy z ich rolami
    let members: [GroupMember]
    
    /// Czy grupa jest zarchiwizowana
    let isArchived: Bool
    
    /// Data utworzenia grupy
    let createdAt: Date
    
    /// Data ostatniej aktualizacji grupy
    let updatedAt: Date
    
    /// Saldo bieżącego użytkownika w grupie (opcjonalne)
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
    
    /// Sprawdza czy bieżący użytkownik jest właścicielem (administratorem) grupy
    var isOwner: Bool {
        guard let currentUserId = AppState.shared.currentUser?.id else { return false }
        return isAdmin(userId: currentUserId)
    }
    
    /// Zwraca liczbę członków grupy
    var memberCount: Int {
        return members.count
    }
    
    /// Sprawdza czy użytkownik o podanym ID jest administratorem grupy
    /// - Parameter userId: ID użytkownika do sprawdzenia
    /// - Returns: true jeśli użytkownik jest administratorem, false w przeciwnym razie
    func isAdmin(userId: String) -> Bool {
        return members.first(where: { $0.user.id == userId })?.role == "admin"
    }
}

/// Model reprezentujący członka grupy z jego rolą i datą dołączenia
struct GroupMember: Identifiable, Codable {
    /// Unikalny identyfikator członkostwa
    let id: String
    
    /// Dane użytkownika będącego członkiem grupy
    let user: GroupUser
    
    /// Rola użytkownika w grupie (admin/member)
    let role: String
    
    /// Data dołączenia do grupy
    let joined: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user
        case role
        case joined
    }
}

/// Model reprezentujący użytkownika w kontekście grupy
/// Zawiera podstawowe informacje potrzebne do wyświetlania w grupie
struct GroupUser: Identifiable, Codable {
    /// Unikalny identyfikator użytkownika
    let id: String
    
    /// Imię użytkownika
    let firstName: String
    
    /// Nazwisko użytkownika
    let lastName: String
    
    /// Adres email użytkownika
    let email: String
    
    /// Opcjonalny avatar użytkownika (URL do zdjęcia)
    let avatar: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName
        case lastName
        case email
        case avatar
    }
    
    /// Zwraca inicjały użytkownika (pierwsze litery imienia i nazwiska)
    var initials: String {
        let firstNameInitial = firstName.prefix(1).uppercased()
        let lastNameInitial = lastName.prefix(1).uppercased()
        return "\(firstNameInitial)\(lastNameInitial)"
    }
    
    /// Zwraca pełne imię i nazwisko do wyświetlania
    var displayName: String {
        return "\(firstName) \(lastName)"
    }
}

// MARK: - Struktury odpowiedzi z API

/// Odpowiedź API zawierająca listę grup
struct GroupsResponse: Codable {
    /// Status powodzenia operacji
    let success: Bool
    
    /// Lista grup zwrócona z API
    let groups: [Group]
}

/// Odpowiedź API zawierająca pojedynczą grupę
struct GroupResponse: Codable {
    /// Status powodzenia operacji
    let success: Bool
    
    /// Grupa zwrócona z API
    let group: Group
}

