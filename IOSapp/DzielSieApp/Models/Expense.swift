//
//  Expense.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 06/04/2025.
//

import Foundation

/// Model reprezentujący wydatek w grupie
/// Zawiera wszystkie informacje o wydatku, w tym podział między użytkowników
struct Expense: Identifiable, Codable {
    /// Unikalny identyfikator wydatku
    let id: String
    
    /// ID grupy, do której należy wydatek
    let group: String
    
    /// Opis wydatku
    let description: String
    
    /// Kwota wydatku
    let amount: Double
    
    /// Waluta wydatku
    let currency: String
    
    /// Użytkownik który zapłacił za wydatek
    let paidBy: User
    
    /// Data wydatku
    let date: Date
    
    /// Kategoria wydatku (jedzenie, transport, itp.)
    let category: ExpenseCategory
    
    /// Typ podziału wydatku (równo, procentowo, itp.)
    let splitType: SplitType
    
    /// Lista podziałów wydatku między użytkowników
    let splits: [ExpenseSplit]
    
    /// Opcjonalne zdjęcie paragonu (URL)
    let receipt: String?
    
    /// Opcjonalne flagi wydatku (pilne, sporne, itp.)
    let flags: [ExpenseFlag]?
    
    /// Opcjonalne komentarze do wydatku
    let comments: [ExpenseComment]?
    
    /// Data utworzenia wydatku
    let createdAt: Date
    
    /// Data ostatniej aktualizacji wydatku
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case group
        case description
        case amount
        case currency
        case paidBy
        case date
        case category
        case splitType
        case splits
        case receipt
        case flags
        case comments
        case createdAt
        case updatedAt
    }
}

/// Enum reprezentujący kategorie wydatków
/// CaseIterable pozwala na iterację po wszystkich przypadkach
enum ExpenseCategory: String, Codable, CaseIterable {
    case food = "food"                      // Jedzenie
    case transport = "transport"            // Transport
    case accommodation = "accommodation"    // Zakwaterowanie
    case entertainment = "entertainment"    // Rozrywka
    case utilities = "utilities"            // Rachunki
    case other = "other"                    // Inne
    
    /// Zwraca czytelne nazwy kategorii po polsku
    var displayName: String {
        switch self {
        case .food:
            return "Jedzenie"
        case .transport:
            return "Transport"
        case .accommodation:
            return "Zakwaterowanie"
        case .entertainment:
            return "Rozrywka"
        case .utilities:
            return "Rachunki"
        case .other:
            return "Inne"
        }
    }
    
    /// Zwraca nazwę ikony SF Symbols dla danej kategorii
    var icon: String {
        switch self {
        case .food:
            return "fork.knife"              // Widelec i nóż
        case .transport:
            return "car.fill"               // Samochód
        case .accommodation:
            return "house.fill"             // Dom
        case .entertainment:
            return "ticket.fill"            // Bilet
        case .utilities:
            return "bolt.fill"              // Błyskawica
        case .other:
            return "ellipsis.circle.fill"  // Wielokropek
        }
    }
}

/// Enum reprezentujący sposoby podziału wydatku
enum SplitType: String, Codable, CaseIterable {
    case equal = "equal"            // Podział równy
    case percentage = "percentage"  // Podział procentowy
    case exact = "exact"            // Dokładne kwoty
    case shares = "shares"          // Podział na udziały
    
    var displayName: String {
        switch self {
        case .equal:
            return "Po równo"
        case .percentage:
            return "Procentowo"
        case .exact:
            return "Dokładne kwoty"
        case .shares:
            return "Udziały"
        }
    }
    
    var icon: String {
        switch self {
        case .equal:
            return "equal.square.fill"
        case .percentage:
            return "percent"
        case .exact:
            return "number.square.fill"
        case .shares:
            return "chart.pie.fill"
        }
    }
}

/// Model reprezentujący podział wydatku dla konkretnego użytkownika
struct ExpenseSplit: Identifiable, Codable {
    /// Unikalny identyfikator podziału
    let id: String
    
    /// Użytkownik którego dotyczy podział
    let user: User
    
    /// Kwota przypadająca na tego użytkownika
    let amount: Double
    
    /// Procent (jeśli typ podziału to percentage)
    let percentage: Double?
    
    /// Liczba udziałów (jeśli typ podziału to shares)
    let shares: Int?
    
    /// Czy użytkownik już rozliczył swoją część
    let settled: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user
        case amount
        case percentage
        case shares
        case settled
    }
}

/// Flagi możliwe do ustawienia na wydatku
enum ExpenseFlag: String, Codable {
    case pending = "pending"      // Oczekujący
    case urgent = "urgent"        // Pilny
    case disputed = "disputed"    // Sporny
}

/// Model reprezentujący komentarz do wydatku
struct ExpenseComment: Identifiable, Codable {
    /// Unikalny identyfikator komentarza
    let id: String
    
    /// Użytkownik który napisał komentarz
    let user: User
    
    /// Treść komentarza
    let text: String
    
    /// Data utworzenia komentarza
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user
        case text
        case createdAt
    }
}

// Struktury pomocnicze do tworzenia nowego wydatku
struct ExpenseCreateData: Codable {
    let group: String
    let description: String
    let amount: Double
    let currency: String
    let paidBy: String
    let date: Date
    let category: String
    let splitType: String
    let splits: [ExpenseSplitCreateData]
    let flags: [String]?
}

struct ExpenseSplitCreateData: Codable {
    let user: String
    let amount: Double
    let percentage: Double?
    let shares: Int?
}

// Struktury odpowiedzi z API
struct ExpenseResponse: Codable {
    let success: Bool
    let message: String?
    let expense: Expense
}

struct ExpensesResponse: Codable {
    let success: Bool
    let expenses: [Expense]
    let pagination: PaginationInfo
}

struct PaginationInfo: Codable {
    let totalDocs: Int
    let limit: Int
    let totalPages: Int
    let page: Int
    let hasPrevPage: Bool
    let hasNextPage: Bool
    let prevPage: Int?
    let nextPage: Int?
}
