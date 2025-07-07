//
//  ActivityModel.swift
//  DzielSieApp
//
//  Created by Claude on 06/04/2025.
//

import Foundation

struct Activity: Identifiable {
    let id: String
    let type: ActivityType
    let title: String
    let subtitle: String
    let amount: Double?
    let currency: String
    let date: Date
    let iconName: String
    let groupId: String?
    let expenseId: String?
    
    var formattedDate: String {
        // Format relative date (today, yesterday, X days ago)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var formattedAmount: String? {
        guard let amount = amount else { return nil }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: amount))
    }
}

enum ActivityType {
    case newExpense
    case addedToGroup
    case settledExpense
    case groupCreated
    case memberAdded
}
