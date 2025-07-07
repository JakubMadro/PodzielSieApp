//
//  UserBalanceResponse.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 10/06/2025.
//


import Foundation
import SwiftUI

// MARK: - User Balance Response
struct UserBalanceResponse: Codable {
    let success: Bool
    let balance: UserBalanceDetails
}

// MARK: - User Balance
struct UserBalanceDetails: Codable {
    let userId: String
    let groupId: String
    let currency: String
    let totalPaid: Double
    let totalOwed: Double
    let balance: Double
    let amountToPay: Double
    let amountToReceive: Double
    let netBalance: Double
    let status: String
    let activeSettlements: [ActiveSettlement]
    
    // Computed properties
    var balanceStatus: BalanceStatus {
        switch status {
        case "creditor":
            return .creditor
        case "debtor":
            return .debtor
        default:
            return .even
        }
    }
    
    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        
        if let formatted = formatter.string(from: NSNumber(value: abs(balance))) {
            if balance < 0 {
                return "-\(formatted)"
            } else if balance > 0 {
                return "+\(formatted)"
            } else {
                return formatted
            }
        }
        
        return String(format: "%.2f %@", balance, currency)
    }
    
    var formattedAmountToPay: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: amountToPay)) ?? "\(amountToPay) \(currency)"
    }
    
    var formattedAmountToReceive: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: amountToReceive)) ?? "\(amountToReceive) \(currency)"
    }
     func formattedAmountFromTotal(_ amount: Double) -> String {
         let formatter = NumberFormatter()
         formatter.numberStyle = .currency
         formatter.currencyCode = currency
         formatter.maximumFractionDigits = 2
         
         return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
     }
}

// MARK: - Active Settlement
struct ActiveSettlement: Codable {
    let id: String
    let amount: Double
    let currency: String
    let type: String // "owes" or "owed"
    let otherUser: SettlementUser
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
    }
    
    var typeDescription: String {
        return type == "owes" ? "Jesteś winien" : "Ma Ci zapłacić"
    }
}

// MARK: - Settlement User
struct SettlementUser: Codable {
    let id: String
    let name: String
    let email: String
}

// MARK: - Balance Status
enum BalanceStatus {
    case creditor   // Na plusie (ma otrzymać pieniądze)
    case debtor     // Na minusie (musi zapłacić)
    case even       // Wyrównane
    
    var color: Color {
        switch self {
        case .creditor:
            return .green
        case .debtor:
            return .red
        case .even:
            return .primary
        }
    }
    
    var description: String {
        switch self {
        case .creditor:
            return "Na plusie"
        case .debtor:
            return "Do zapłaty"
        case .even:
            return "Wyrównane"
        }
    }
    
    var icon: String {
        switch self {
        case .creditor:
            return "arrow.up.circle.fill"
        case .debtor:
            return "arrow.down.circle.fill"
        case .even:
            return "equal.circle.fill"
        }
    }
}
