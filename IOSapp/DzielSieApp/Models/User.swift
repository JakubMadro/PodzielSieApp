//
//  User.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 05/04/2025.
//

import Foundation

/// Model reprezentujący użytkownika w aplikacji
/// Struktury Codable umożliwiają łatwą serializację/deserializację do/z JSON
struct User: Codable {
    /// Unikalny identyfikator użytkownika z bazy danych
    let id: String
    
    /// Imię użytkownika
    let firstName: String
    
    /// Nazwisko użytkownika  
    let lastName: String
    
    /// Adres email użytkownika (unikalny w systemie)
    let email: String
    
    /// Mapowanie kluczy JSON na właściwości Swift
    /// _id z MongoDB jest mapowane na id w Swift
    enum CodingKeys: String, CodingKey {
        case id = "_id"        // MongoDB używa _id zamiast id
        case firstName
        case lastName
        case email
    }
}

// MARK: - Rozszerzenia User
extension User {
    /// Zwraca pełne imię i nazwisko użytkownika
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    /// Zwraca inicjały użytkownika (pierwsze litery imienia i nazwiska)
    var initials: String {
        let firstInitial = firstName.prefix(1).uppercased()
        let lastInitial = lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }
}
