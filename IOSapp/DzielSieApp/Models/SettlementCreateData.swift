//
//  SettlementCreateData.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 10/06/2025.
//


import Foundation

// MARK: - Settlement Create Data
struct SettlementCreateData: Codable {
    let groupId: String
    let toUserId: String
    let amount: Double
    let currency: String?
    let paymentMethod: String?
    let paymentReference: String?
}