////
////  GroupBalancesResponse.swift
////  DzielSieApp
////
////  Created by Kuba Mądro on 10/06/2025.
////
//
//
//import Foundation
//
//// MARK: - Group Balances Response
//struct GroupBalancesResponse: Codable {
//    let success: Bool
//    let userSettlements: [Settlement]
//    let otherSettlements: [Settlement]
//    let totalSettlements: Int
//    let summary: BalanceSummary?
//}
//
//// MARK: - Settlement
//struct Settlement: Identifiable, Codable {
//    let id: String
//    let payer: SettlementUser
//    let receiver: SettlementUser
//    let amount: Double
//    let currency: String
//    let status: String
//    let group: String
//    let createdAt: Date
//    let updatedAt: Date
//    
//    enum CodingKeys: String, CodingKey {
//        case id = "_id"
//        case payer
//        case receiver
//        case amount
//        case currency
//        case status
//        case group
//        case createdAt
//        case updatedAt
//    }
//}
//
//// MARK: - Balance Summary
//struct BalanceSummary: Codable {
//    let currency: String
//    let userStatus: String
//    let userNetBalance: Double
//    let totalToPay: Double
//    let totalToReceive: Double
//}
//
//// MARK: - Settlement User (już zdefiniowany w UserBalance.swift, ale duplikujemy dla jasności)
//// struct SettlementUser: Codable {
////     let id: String
////     let name: String
////     let email: String
//// }
//
//// MARK: - User Balance (dla compatibility z istniejącym kodem)
//struct UserBalance: Identifiable, Codable {
//    let id: String
//    let firstName: String
//    let lastName: String
//    let email: String
//    let balance: Double
//    
//    enum CodingKeys: String, CodingKey {
//        case id = "_id"
//        case firstName
//        case lastName
//        case email
//        case balance
//    }
//}
//
//// MARK: - Settlement Suggestion
//struct SettlementSuggestion: Identifiable, Codable {
//    let id = UUID()
//    let payer: SettlementUser
//    let receiver: SettlementUser
//    let amount: Double
//    
//    enum CodingKeys: String, CodingKey {
//        case payer
//        case receiver
//        case amount
//    }
//}
//
//// MARK: - Mock Response dla development (usuń to gdy backend będzie gotowy)
//struct MockGroupBalancesResponse: Codable {
//    let success: Bool
//    let balances: [UserBalance]
//    let currency: String
//    let settlementSuggestions: [SettlementSuggestion]
//}
