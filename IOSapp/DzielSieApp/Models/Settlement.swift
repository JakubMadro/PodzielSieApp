//
//  Settlement.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//

import Foundation

// Pomocnicza struktura dla dekodowania group jako obiekt
struct GroupReference: Codable {
    let id: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
    }
}

// Pomocnicza struktura dla dekodowania relatedExpenses jako obiekty
struct ExpenseReference: Codable {
    let id: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
    }
}

struct Settlement: Identifiable, Codable {
    let id: String
    let group: String
    let payer: User
    let receiver: User
    let amount: Double
    let currency: String
    let date: Date
    let status: SettlementStatus
    let paymentMethod: PaymentMethod?
    let paymentReference: String?
    let relatedExpenses: [String]?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case group
        case payer
        case receiver
        case amount
        case currency
        case date
        case status
        case paymentMethod
        case paymentReference
        case relatedExpenses
        case createdAt
        case updatedAt
    }
    // NIESTANDARDOWY DECODER - OSZUKUJEMY SYSTEM! 🎭
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            id = try container.decode(String.self, forKey: .id)
            
            // MAGIA dla pola group! 🪄 Obsłuż zarówno String jak i obiekt
            if let groupString = try? container.decode(String.self, forKey: .group) {
                group = groupString
            } else if let groupObject = try? container.decode(GroupReference.self, forKey: .group) {
                group = groupObject.id
            } else {
                group = ""
            }
            
            payer = try container.decode(User.self, forKey: .payer)
            receiver = try container.decode(User.self, forKey: .receiver)
            amount = try container.decode(Double.self, forKey: .amount)
            currency = try container.decode(String.self, forKey: .currency)
            status = try container.decode(SettlementStatus.self, forKey: .status)
            paymentMethod = try container.decodeIfPresent(PaymentMethod.self, forKey: .paymentMethod)
            paymentReference = try container.decodeIfPresent(String.self, forKey: .paymentReference)
            
            // MAGIA dla relatedExpenses! 🪄 Obsłuż zarówno [String] jak i [Object]
            if let expenseStrings = try? container.decodeIfPresent([String].self, forKey: .relatedExpenses) {
                relatedExpenses = expenseStrings
            } else if let expenseObjects = try? container.decodeIfPresent([ExpenseReference].self, forKey: .relatedExpenses) {
                relatedExpenses = expenseObjects.map { $0.id }
            } else {
                relatedExpenses = nil
            }
            createdAt = try container.decode(Date.self, forKey: .createdAt)
            updatedAt = try container.decode(Date.self, forKey: .updatedAt)
            
            // MAGIA! 🪄 Jeśli backend nie zwraca 'date', użyj 'createdAt'
            if let dateFromBackend = try container.decodeIfPresent(Date.self, forKey: .date) {
                date = dateFromBackend
            } else {
                date = createdAt  // Oszukujemy - używamy createdAt jako date!
            }
        }
}

enum SettlementStatus: String, Codable {
    case pending = "pending"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Oczekujące"
        case .completed:
            return "Zrealizowane"
        case .cancelled:
            return "Anulowane"
        }
    }
    
    var icon: String {
        switch self {
        case .pending:
            return "clock.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .cancelled:
            return "xmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .pending:
            return "yellow"
        case .completed:
            return "green"
        case .cancelled:
            return "red"
        }
    }
}

enum PaymentMethod: String, Codable {
    case manual = "manual"
    case paypal = "paypal"
    case blik = "blik"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .manual:
            return "Gotówka"
        case .paypal:
            return "PayPal"
        case .blik:
            return "BLIK"
        case .other:
            return "Inna metoda"
        }
    }
    
    var icon: String {
        switch self {
        case .manual:
            return "banknote"
        case .paypal:
            return "p.circle.fill"
        case .blik:
            return "qrcode"
        case .other:
            return "creditcard"
        }
    }
}

// Struktury odpowiedzi z API
struct SettlementResponse: Codable {
    let success: Bool
    let settlement: Settlement
}

struct SettlementsResponse: Codable {
    let success: Bool
    let settlements: [Settlement]
    let pagination: PaginationInfo?
}

struct GroupBalancesResponse: Codable {
    let success: Bool
    let userSettlements: [Settlement]
    let otherSettlements: [Settlement]
    let totalSettlements: Int
    let summary: BalanceSummary?
    
    // Jeśli backend zwraca starą strukturę, dodaj też te pola dla compatibility:
    let balances: [UserBalance]?
    let currency: String?
    let settlementSuggestions: [SettlementSuggestion]?
}

struct BalanceSummary: Codable {
    let currency: String
    let userStatus: String
    let userNetBalance: Double
    let totalToPay: Double
    let totalToReceive: Double
}

// Struktura UserBalance - zaktualizowana żeby pasowała do backendu
struct UserBalance: Codable, Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let balance: Double
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"  // Backend zwraca _id
        case firstName
        case lastName
        case email
        case balance
    }
}

// Struktura SettlementSuggestion - zaktualizowana
struct SettlementSuggestion: Codable, Identifiable {
    var id: String { "\(fromUser.id)-\(toUser.id)" }
    let fromUser: UserInfo
    let toUser: UserInfo
    let amount: Double
    
    // Computed properties dla compatibility z istniejącym kodem
    var payer: UserInfo { fromUser }
    var receiver: UserInfo { toUser }
}

// Dodaj nową strukturę UserInfo dla settlement suggestions
struct UserInfo: Codable {
    let id: String
    let name: String
    let email: String
    
    // Computed properties dla compatibility
    var firstName: String {
        return name.components(separatedBy: " ").first ?? ""
    }
    
    var lastName: String {
        return name.components(separatedBy: " ").dropFirst().joined(separator: " ")
    }
}
