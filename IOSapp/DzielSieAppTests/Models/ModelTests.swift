//
//  ModelTests.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//

import XCTest
@testable import DzielSieApp

final class ModelTests: XCTestCase {
    
    // MARK: - Testy modelu User
    
    func testUser_Initialization() {
        // Given
        let id = "user-123"
        let firstName = "John"
        let lastName = "Doe"
        let email = "john.doe@example.com"
        
        // When
        let user = User(id: id, firstName: firstName, lastName: lastName, email: email)
        
        // Then
        XCTAssertEqual(user.id, id)
        XCTAssertEqual(user.firstName, firstName)
        XCTAssertEqual(user.lastName, lastName)
        XCTAssertEqual(user.email, email)
    }
    
    func testUser_Codable() throws {
        // Given
        let user = User(id: "123", firstName: "John", lastName: "Doe", email: "john@example.com")
        
        // Wykonanie - kodowanie
        let encoder = JSONEncoder()
        let data = try encoder.encode(user)
        
        // Sprawdzenie - dekodowanie
        let decoder = JSONDecoder()
        let decodedUser = try decoder.decode(User.self, from: data)
        
        XCTAssertEqual(user.id, decodedUser.id)
        XCTAssertEqual(user.firstName, decodedUser.firstName)
        XCTAssertEqual(user.lastName, decodedUser.lastName)
        XCTAssertEqual(user.email, decodedUser.email)
    }
    
    // MARK: - Testy modelu Group
    
    func testGroup_Initialization() {
        // Given
        let id = "group-123"
        let name = "Test Group"
        let description = "Test Description"
        let defaultCurrency = "PLN"
        let members: [GroupMember] = []
        let isArchived = false
        let createdAt = Date()
        let updatedAt = Date()
        
        // When
        let group = Group(
            id: id,
            name: name,
            description: description,
            defaultCurrency: defaultCurrency,
            owner: User(id: "owner-id", firstName: "Owner", lastName: "User", email: "owner@example.com"),
            members: members,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isArchived: isArchived
        )
        
        // Then
        XCTAssertEqual(group.id, id)
        XCTAssertEqual(group.name, name)
        XCTAssertEqual(group.description, description)
        XCTAssertEqual(group.defaultCurrency, defaultCurrency)
        XCTAssertEqual(group.members.count, 0)
        XCTAssertEqual(group.isArchived, isArchived)
    }
    
    func testGroup_WithMembers() {
        // Given
        let member1 = GroupMember(
            id: "member-1",
            user: User(id: "user-1", firstName: "User", lastName: "One", email: "user1@example.com"),
            role: "member",
            joinedAt: Date()
        )
        let member2 = GroupMember(
            id: "member-2",
            user: User(id: "user-2", firstName: "User", lastName: "Two", email: "user2@example.com"),
            role: "admin",
            joinedAt: Date()
        )
        
        // When
        let group = Group(
            id: "group-123",
            name: "Test Group",
            description: "Test Description",
            defaultCurrency: "PLN",
            owner: User(id: "owner-id", firstName: "Owner", lastName: "User", email: "owner@example.com"),
            members: [member1, member2],
            createdAt: Date(),
            updatedAt: Date(),
            isArchived: false
        )
        
        // Then
        XCTAssertEqual(group.members.count, 2)
        XCTAssertEqual(group.members[0].role, "member")
        XCTAssertEqual(group.members[1].role, "admin")
    }
    
    // MARK: - Testy modelu Expense
    
    func testExpense_Initialization() {
        // Given
        let id = "expense-123"
        let groupId = "group-123"
        let description = "Test Expense"
        let amount = 100.0
        let currency = "PLN"
        let paidBy = User(id: "user-1", firstName: "John", lastName: "Doe", email: "john@example.com")
        let date = Date()
        let category = ExpenseCategory.food
        let splitType = SplitType.equal
        let splits: [ExpenseSplit] = []
        
        // When
        let expense = Expense(
            id: id,
            group: groupId,
            description: description,
            amount: amount,
            currency: currency,
            paidBy: paidBy,
            date: date,
            category: category,
            splitType: splitType,
            splits: splits,
            receipt: nil,
            flags: nil,
            comments: nil,
            createdAt: date,
            updatedAt: date
        )
        
        // Then
        XCTAssertEqual(expense.id, id)
        XCTAssertEqual(expense.group, groupId)
        XCTAssertEqual(expense.description, description)
        XCTAssertEqual(expense.amount, amount)
        XCTAssertEqual(expense.currency, currency)
        XCTAssertEqual(expense.paidBy.id, paidBy.id)
        XCTAssertEqual(expense.category, category)
        XCTAssertEqual(expense.splitType, splitType)
        XCTAssertNil(expense.receipt)
        XCTAssertNil(expense.flags)
        XCTAssertNil(expense.comments)
    }
    
    func testExpenseCategory_AllCases() {
        // Given
        let expectedCategories: [ExpenseCategory] = [.food, .transport, .accommodation, .entertainment, .utilities, .healthcare, .shopping, .education, .other]
        
        // When
        let allCases = ExpenseCategory.allCases
        
        // Then
        XCTAssertEqual(allCases.count, expectedCategories.count)
        for category in expectedCategories {
            XCTAssertTrue(allCases.contains(category))
        }
    }
    
    func testSplitType_AllCases() {
        // Given
        let expectedTypes: [SplitType] = [.equal, .exact, .percentage, .shares]
        
        // When
        let allCases = SplitType.allCases
        
        // Then
        XCTAssertEqual(allCases.count, expectedTypes.count)
        for type in expectedTypes {
            XCTAssertTrue(allCases.contains(type))
        }
    }
    
    // MARK: - Testy modelu Activity
    
    func testActivity_Initialization() {
        // Given
        let id = "activity-123"
        let type = ActivityType.newExpense
        let title = "Test Activity"
        let subtitle = "Test Subtitle"
        let amount = 50.0
        let currency = "PLN"
        let date = Date()
        let iconName = "dollarsign.circle"
        let groupId = "group-123"
        let expenseId = "expense-123"
        
        // When
        let activity = Activity(
            id: id,
            type: type,
            title: title,
            subtitle: subtitle,
            amount: amount,
            currency: currency,
            date: date,
            iconName: iconName,
            groupId: groupId,
            expenseId: expenseId
        )
        
        // Then
        XCTAssertEqual(activity.id, id)
        XCTAssertEqual(activity.type, type)
        XCTAssertEqual(activity.title, title)
        XCTAssertEqual(activity.subtitle, subtitle)
        XCTAssertEqual(activity.amount, amount)
        XCTAssertEqual(activity.currency, currency)
        XCTAssertEqual(activity.iconName, iconName)
        XCTAssertEqual(activity.groupId, groupId)
        XCTAssertEqual(activity.expenseId, expenseId)
    }
    
    func testActivityType_AllCases() {
        // Given
        let expectedTypes: [ActivityType] = [.newExpense, .addedToGroup, .settledExpense, .groupCreated, .memberAdded]
        
        // When
        let allCases = ActivityType.allCases
        
        // Then
        XCTAssertEqual(allCases.count, expectedTypes.count)
        for type in expectedTypes {
            XCTAssertTrue(allCases.contains(type))
        }
    }
    
    // MARK: - Testy modelu UserBalance
    
    func testUserBalanceDetails_Initialization() {
        // Given
        let totalBalance = 100.0
        let totalOwed = 50.0
        let totalOwing = 25.0
        let currency = "PLN"
        let balanceBreakdown: [UserBalance] = []
        
        // When
        let userBalance = UserBalanceDetails(
            totalBalance: totalBalance,
            totalOwed: totalOwed,
            totalOwing: totalOwing,
            currency: currency,
            balanceBreakdown: balanceBreakdown
        )
        
        // Then
        XCTAssertEqual(userBalance.totalBalance, totalBalance)
        XCTAssertEqual(userBalance.totalOwed, totalOwed)
        XCTAssertEqual(userBalance.totalOwing, totalOwing)
        XCTAssertEqual(userBalance.currency, currency)
        XCTAssertEqual(userBalance.balanceBreakdown.count, 0)
    }
    
    // MARK: - Testy modelu GroupMember
    
    func testGroupMember_Initialization() {
        // Given
        let id = "member-123"
        let user = User(id: "user-123", firstName: "John", lastName: "Doe", email: "john@example.com")
        let role = "admin"
        let joinedAt = Date()
        
        // When
        let member = GroupMember(id: id, user: user, role: role, joinedAt: joinedAt)
        
        // Then
        XCTAssertEqual(member.id, id)
        XCTAssertEqual(member.user.id, user.id)
        XCTAssertEqual(member.role, role)
        XCTAssertEqual(member.joinedAt, joinedAt)
    }
    
    // MARK: - Testy modelu ExpenseSplit
    
    func testExpenseSplit_Initialization() {
        // Given
        let id = "split-123"
        let user = User(id: "user-123", firstName: "John", lastName: "Doe", email: "john@example.com")
        let amount = 50.0
        let percentage: Double? = nil
        let shares: Int? = nil
        let settled = false
        
        // When
        let split = ExpenseSplit(
            id: id,
            user: user,
            amount: amount,
            percentage: percentage,
            shares: shares,
            settled: settled
        )
        
        // Then
        XCTAssertEqual(split.id, id)
        XCTAssertEqual(split.user.id, user.id)
        XCTAssertEqual(split.amount, amount)
        XCTAssertNil(split.percentage)
        XCTAssertNil(split.shares)
        XCTAssertFalse(split.settled)
    }
    
    func testExpenseSplit_WithPercentage() {
        // Given
        let split = ExpenseSplit(
            id: "split-123",
            user: User(id: "user-123", firstName: "John", lastName: "Doe", email: "john@example.com"),
            amount: 50.0,
            percentage: 25.0,
            shares: nil,
            settled: true
        )
        
        // When & Then
        XCTAssertEqual(split.percentage, 25.0)
        XCTAssertNil(split.shares)
        XCTAssertTrue(split.settled)
    }
    
    func testExpenseSplit_WithShares() {
        // Given
        let split = ExpenseSplit(
            id: "split-123",
            user: User(id: "user-123", firstName: "John", lastName: "Doe", email: "john@example.com"),
            amount: 50.0,
            percentage: nil,
            shares: 2,
            settled: false
        )
        
        // When & Then
        XCTAssertNil(split.percentage)
        XCTAssertEqual(split.shares, 2)
        XCTAssertFalse(split.settled)
    }
}