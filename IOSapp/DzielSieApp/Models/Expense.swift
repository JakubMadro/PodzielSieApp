//
//  Expense.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 06/04/2025.
//

import Foundation

struct Expense: Identifiable, Codable {
    let id: String
    let group: String
    let description: String
    let amount: Double
    let currency: String
    let paidBy: User
    let date: Date
    let category: ExpenseCategory
    let splitType: SplitType
    let splits: [ExpenseSplit]
    let receipt: String?
    let flags: [ExpenseFlag]?
    let comments: [ExpenseComment]?
    let createdAt: Date
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

enum ExpenseCategory: String, Codable, CaseIterable {
    case food = "food"
    case transport = "transport"
    case accommodation = "accommodation"
    case entertainment = "entertainment"
    case utilities = "utilities"
    case other = "other"
    
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
    
    var icon: String {
        switch self {
        case .food:
            return "fork.knife"
        case .transport:
            return "car.fill"
        case .accommodation:
            return "house.fill"
        case .entertainment:
            return "ticket.fill"
        case .utilities:
            return "bolt.fill"
        case .other:
            return "ellipsis.circle.fill"
        }
    }
}

enum SplitType: String, Codable, CaseIterable {
    case equal = "equal"
    case percentage = "percentage"
    case exact = "exact"
    case shares = "shares"
    
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

struct ExpenseSplit: Identifiable, Codable {
    let id: String
    let user: User
    let amount: Double
    let percentage: Double?
    let shares: Int?
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

enum ExpenseFlag: String, Codable {
    case pending = "pending"
    case urgent = "urgent"
    case disputed = "disputed"
}

struct ExpenseComment: Identifiable, Codable {
    let id: String
    let user: User
    let text: String
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
