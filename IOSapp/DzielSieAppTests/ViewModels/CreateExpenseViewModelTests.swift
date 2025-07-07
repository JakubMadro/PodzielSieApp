//
//  CreateExpenseViewModelTests.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//


import XCTest
import Combine
@testable import DzielSieApp

final class CreateExpenseViewModelTests: XCTestCase {
    
    var viewModel: CreateExpenseViewModel!
    var mockExpenseService: MockExpenseService!
    var mockGroupsService: MockGroupsServiceForTests!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockExpenseService = MockExpenseService()
        mockGroupsService = MockGroupsServiceForTests()
        viewModel = CreateExpenseViewModel(expenseService: mockExpenseService, groupsService: mockGroupsService)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        viewModel = nil
        mockExpenseService = nil
        mockGroupsService = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testLoadGroupMembers_Success() {
        // Given
        let testGroup = MockDataProvider.getMockGroups().first!
        mockGroupsService.fetchGroupDetailsResult = .success(testGroup)
        
        // When
        let expectation = XCTestExpectation(description: "Load group members")
        viewModel.loadGroupMembers(groupId: testGroup.id)
        
        // Wait a bit for the async operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.availableMembers.count, testGroup.members.count)
        XCTAssertEqual(viewModel.currency, testGroup.defaultCurrency)
        XCTAssertEqual(viewModel.splits.count, testGroup.members.count)
    }
    
    func testLoadGroupMembers_Failure() {
        // Given
        let expectedError = APIError.serverError(message: "Failed to load group")
        mockGroupsService.fetchGroupDetailsResult = .failure(expectedError)
        
        // When
        let expectation = XCTestExpectation(description: "Load group members error")
        viewModel.loadGroupMembers(groupId: "test-group-id")
        
        // Wait a bit for the async operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.error, expectedError.localizedDescription)
    }
    
    func testValidateExpense_EmptyDescription() {
        // Given
        viewModel.description = ""
        viewModel.amountText = "100.0"
        viewModel.paidByUserId = "user-id"
        
        // When
        let isValid = viewModel.validateExpense()
        
        // Then
        XCTAssertFalse(isValid)
        XCTAssertEqual(viewModel.error, "Opis wydatku jest wymagany")
    }
    
    func testValidateExpense_InvalidAmount() {
        // Given
        viewModel.description = "Test Expense"
        viewModel.amountText = "0"
        viewModel.paidByUserId = "user-id"
        
        // When
        let isValid = viewModel.validateExpense()
        
        // Then
        XCTAssertFalse(isValid)
        XCTAssertEqual(viewModel.error, "Kwota musi być większa od zera")
    }
    
    func testValidateExpense_NoPayer() {
        // Given
        viewModel.description = "Test Expense"
        viewModel.amountText = "100.0"
        viewModel.paidByUserId = ""
        
        // When
        let isValid = viewModel.validateExpense()
        
        // Then
        XCTAssertFalse(isValid)
        XCTAssertEqual(viewModel.error, "Wybierz osobę, która zapłaciła")
    }
    
    func testValidateExpense_EqualSplit_NoUsersIncluded() {
        // Given
        viewModel.description = "Test Expense"
        viewModel.amountText = "100.0"
        viewModel.paidByUserId = "user-id"
        viewModel.splitType = .equal
        viewModel.splits = [
            SplitItem(userId: "user1", isIncluded: false, amount: nil, percentage: nil, shares: 1),
            SplitItem(userId: "user2", isIncluded: false, amount: nil, percentage: nil, shares: 1)
        ]
        
        // When
        let isValid = viewModel.validateExpense()
        
        // Then
        XCTAssertFalse(isValid)
        XCTAssertEqual(viewModel.error, "Wybierz przynajmniej jedną osobę do podziału kosztów")
    }
    
    func testValidateExpense_PercentageSplit_InvalidTotal() {
        // Given
        viewModel.description = "Test Expense"
        viewModel.amountText = "100.0"
        viewModel.paidByUserId = "user-id"
        viewModel.splitType = .percentage
        
        // Create splits with total percentage != 100%
        let split1 = SplitItem(userId: "user1", isIncluded: true, amount: nil, percentage: 30.0, shares: 1)
        let split2 = SplitItem(userId: "user2", isIncluded: true, amount: nil, percentage: 30.0, shares: 1)
        viewModel.splits = [split1, split2]
        
        // When
        let isValid = viewModel.validateExpense()
        
        // Then
        XCTAssertFalse(isValid)
        XCTAssertEqual(viewModel.error, "Suma procentów musi wynosić 100%")
    }
    
    func testValidateExpense_ExactSplit_InvalidTotal() {
        // Given
        viewModel.description = "Test Expense"
        viewModel.amountText = "100.0"
        viewModel.paidByUserId = "user-id"
        viewModel.splitType = .exact
        
        // Create splits with total amount != expense amount
        let split1 = SplitItem(userId: "user1", isIncluded: true, amount: 30.0, percentage: nil, shares: 1)
        let split2 = SplitItem(userId: "user2", isIncluded: true, amount: 30.0, percentage: nil, shares: 1)
        viewModel.splits = [split1, split2]
        
        // When
        let isValid = viewModel.validateExpense()
        
        // Then
        XCTAssertFalse(isValid)
        XCTAssertEqual(viewModel.error, "Suma kwot podziału musi być równa kwocie całkowitej")
    }
    
    func testValidateExpense_SharesSplit_NoShares() {
        // Given
        viewModel.description = "Test Expense"
        viewModel.amountText = "100.0"
        viewModel.paidByUserId = "user-id"
        viewModel.splitType = .shares
        
        // Create splits with zero total shares
        let split1 = SplitItem(userId: "user1", isIncluded: true, amount: nil, percentage: nil, shares: 0)
        let split2 = SplitItem(userId: "user2", isIncluded: true, amount: nil, percentage: nil, shares: 0)
        viewModel.splits = [split1, split2]
        
        // When
        let isValid = viewModel.validateExpense()
        
        // Then
        XCTAssertFalse(isValid)
        XCTAssertEqual(viewModel.error, "Przydziel przynajmniej jeden udział")
    }
    
    func testValidateExpense_Valid() {
        // Given
        viewModel.description = "Test Expense"
        viewModel.amountText = "100.0"
        viewModel.paidByUserId = "user-id"
        viewModel.splitType = .equal
        
        // Create valid splits
        let split1 = SplitItem(userId: "user1", isIncluded: true, amount: nil, percentage: nil, shares: 1)
        let split2 = SplitItem(userId: "user2", isIncluded: true, amount: nil, percentage: nil, shares: 1)
        viewModel.splits = [split1, split2]
        
        // When
        let isValid = viewModel.validateExpense()
        
        // Then
        XCTAssertTrue(isValid)
        XCTAssertNil(viewModel.error)
    }
    
    func testCreateExpense_Success() {
        // Given
        let mockExpense = Expense(
            id: "test-expense-id",
            group: "test-group-id",
            description: "Test Expense",
            amount: 100.0,
            currency: "PLN",
            paidBy: User(id: "user-id", firstName: "Test", lastName: "User", email: "test@example.com"),
            date: Date(),
            category: .other,
            splitType: .equal,
            splits: [],
            receipt: nil,
            flags: nil,
            comments: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockExpenseService.createExpenseResult = .success(mockExpense)
        
        // Setup view model
        viewModel.description = "Test Expense"
        viewModel.amountText = "100.0"
        viewModel.paidByUserId = "user-id"
        viewModel.splitType = .equal
        
        // Create valid splits
        let split1 = SplitItem(userId: "user1", isIncluded: true, amount: nil, percentage: nil, shares: 1)
        let split2 = SplitItem(userId: "user2", isIncluded: true, amount: nil, percentage: nil, shares: 1)
        viewModel.splits = [split1, split2]
        
        // When
        let expectation = XCTestExpectation(description: "Create expense")
        var completionResult = false
        
        viewModel.createExpense(groupId: "test-group-id") { success in
            completionResult = success
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertTrue(completionResult)
    }
    
    func testCreateExpense_Failure() {
        // Given
        let expectedError = APIError.serverError(message: "Failed to create expense")
        mockExpenseService.createExpenseResult = .failure(expectedError)
        
        // Setup view model
        viewModel.description = "Test Expense"
        viewModel.amountText = "100.0"
        viewModel.paidByUserId = "user-id"
        viewModel.splitType = .equal
        
        // Create valid splits
        let split1 = SplitItem(userId: "user1", isIncluded: true, amount: nil, percentage: nil, shares: 1)
        let split2 = SplitItem(userId: "user2", isIncluded: true, amount: nil, percentage: nil, shares: 1)
        viewModel.splits = [split1, split2]
        
        // When
        let expectation = XCTestExpectation(description: "Create expense error")
        var completionResult = true
        
        viewModel.createExpense(groupId: "test-group-id") { success in
            completionResult = success
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.error, expectedError.localizedDescription)
        XCTAssertFalse(completionResult)
    }
}

// Mock ExpenseService for testing
class MockExpenseService: ExpenseServiceProtocol {
    var createExpenseResult: Result<Expense, Error> = .success(
        Expense(
            id: "test-expense-id",
            group: "test-group-id",
            description: "Test Expense",
            amount: 100.0,
            currency: "PLN",
            paidBy: User(id: "user-id", firstName: "Test", lastName: "User", email: "test@example.com"),
            date: Date(),
            category: .food,
            splitType: .equal,
            splits: [],
            receipt: nil,
            flags: nil,
            comments: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    )
    
    var getGroupExpensesResult: Result<ExpensesResponse, Error> = .success(
        ExpensesResponse(
            success: true,
            expenses: [],
            pagination: PaginationInfo(
                totalDocs: 0,
                limit: 20,
                totalPages: 0,
                page: 1,
                hasPrevPage: false,
                hasNextPage: false,
                prevPage: nil,
                nextPage: nil
            )
        )
    )
    
    var getExpenseDetailsResult: Result<Expense, Error> = .success(
        Expense(
            id: "test-expense-id",
            group: "test-group-id",
            description: "Test Expense",
            amount: 100.0,
            currency: "PLN",
            paidBy: User(id: "user-id", firstName: "Test", lastName: "User", email: "test@example.com"),
            date: Date(),
            category: .food,
            splitType: .equal,
            splits: [],
            receipt: nil,
            flags: nil,
            comments: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    )
    
    var updateExpenseResult: Result<Expense, Error> = .success(
        Expense(
            id: "test-expense-id",
            group: "test-group-id",
            description: "Updated Expense",
            amount: 150.0,
            currency: "PLN",
            paidBy: User(id: "user-id", firstName: "Test", lastName: "User", email: "test@example.com"),
            date: Date(),
            category: .food,
            splitType: .equal,
            splits: [],
            receipt: nil,
            flags: nil,
            comments: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    )
    
    var deleteExpenseResult: Result<Bool, Error> = .success(true)
    var addCommentResult: Result<ExpenseComment, Error> = .success(
        ExpenseComment(
            id: "test-comment-id",
            user: User(id: "user-id", firstName: "Test", lastName: "User", email: "test@example.com"),
            text: "Test comment",
            createdAt: Date()
        )
    )
    
    func createExpense(_ expenseData: ExpenseCreateData) -> AnyPublisher<Expense, Error> {
        return result(createExpenseResult)
    }
    
    func getGroupExpenses(groupId: String, page: Int, limit: Int) -> AnyPublisher<ExpensesResponse, Error> {
        return result(getGroupExpensesResult)
    }
    
    func getExpenseDetails(expenseId: String) -> AnyPublisher<Expense, Error> {
        return result(getExpenseDetailsResult)
    }
    
    func updateExpense(expenseId: String, updateData: [String : Any]) -> AnyPublisher<Expense, Error> {
        return result(updateExpenseResult)
    }
    
    func deleteExpense(expenseId: String) -> AnyPublisher<Bool, Error> {
        return result(deleteExpenseResult)
    }
    
    func addComment(expenseId: String, text: String) -> AnyPublisher<ExpenseComment, Error> {
        return result(addCommentResult)
    }
    
    private func result<T>(_ result: Result<T, Error>) -> AnyPublisher<T, Error> {
        return result.publisher
            .delay(for: .milliseconds(10), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}