//
//  ExpenseServiceTests.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//


import XCTest
import Combine
@testable import DzielSieApp

final class ExpenseServiceTests: XCTestCase {
    
    var expenseService: ExpenseService!
    var mockNetworkService: MockNetworkServiceForExpenses!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkServiceForExpenses()
        expenseService = ExpenseService(networkService: mockNetworkService)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        expenseService = nil
        mockNetworkService = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testCreateExpense_Success() {
        // Given
        let mockExpense = createMockExpense()
        let expenseData = createMockExpenseData()
        let mockResponse = ExpenseResponse(success: true, message: "Expense created", expense: mockExpense)
        
        mockNetworkService.mockData = try! JSONEncoder().encode(mockResponse)
        
        // When
        let expectation = XCTestExpectation(description: "Create expense")
        var resultExpense: Expense?
        var resultError: Error?
        
        expenseService.createExpense(expenseData)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { expense in
                resultExpense = expense
            })
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertNotNil(resultExpense)
        XCTAssertEqual(resultExpense?.id, mockExpense.id)
        XCTAssertEqual(resultExpense?.description, mockExpense.description)
        XCTAssertEqual(resultExpense?.amount, mockExpense.amount)
    }
    
    func testGetGroupExpenses_Success() {
        // Given
        let mockExpenses = [createMockExpense(), createMockExpense()]
        let mockResponse = ExpensesResponse(
            success: true,
            expenses: mockExpenses,
            pagination: PaginationInfo(
                totalDocs: 2,
                limit: 10,
                totalPages: 1,
                page: 1,
                hasPrevPage: false,
                hasNextPage: false,
                prevPage: nil,
                nextPage: nil
            )
        )
        
        mockNetworkService.mockData = try! JSONEncoder().encode(mockResponse)
        
        // When
        let expectation = XCTestExpectation(description: "Get group expenses")
        var resultResponse: ExpensesResponse?
        var resultError: Error?
        
        expenseService.getGroupExpenses(groupId: "test-group", page: 1, limit: 10)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { response in
                resultResponse = response
            })
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertNotNil(resultResponse)
        XCTAssertEqual(resultResponse?.expenses.count, 2)
        XCTAssertEqual(resultResponse?.pagination.totalDocs, 2)
    }
    
    func testUpdateExpense_Success() {
        // Given
        let mockExpense = createMockExpense()
        let updateData: [String: Any] = ["description": "Updated description", "amount": 150.0]
        let updatedMockExpense = createMockExpense(description: "Updated description", amount: 150.0)
        let mockResponse = ExpenseResponse(success: true, message: "Expense updated", expense: updatedMockExpense)
        
        mockNetworkService.mockData = try! JSONEncoder().encode(mockResponse)
        
        // When
        let expectation = XCTestExpectation(description: "Update expense")
        var resultExpense: Expense?
        var resultError: Error?
        
        expenseService.updateExpense(expenseId: mockExpense.id, updateData: updateData)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { expense in
                resultExpense = expense
            })
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertNotNil(resultExpense)
        XCTAssertEqual(resultExpense?.description, "Updated description")
        XCTAssertEqual(resultExpense?.amount, 150.0)
    }
    
    func testDeleteExpense_Success() {
        // Given
        let mockResponse = DeleteResponse(success: true, message: "Expense deleted")
        mockNetworkService.mockData = try! JSONEncoder().encode(mockResponse)
        
        // When
        let expectation = XCTestExpectation(description: "Delete expense")
        var resultSuccess: Bool?
        var resultError: Error?
        
        expenseService.deleteExpense(expenseId: "test-expense-id")
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { success in
                resultSuccess = success
            })
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertNotNil(resultSuccess)
        XCTAssertTrue(resultSuccess!)
    }
    
    // Helper methods to create mock data
    private func createMockExpense(
        id: String = "test-expense-id",
        description: String = "Test Expense",
        amount: Double = 100.0
    ) -> Expense {
        return Expense(
            id: id,
            group: "test-group-id",
            description: description,
            amount: amount,
            currency: "PLN",
            paidBy: User(id: "test-user-id", firstName: "Test", lastName: "User", email: "test@example.com"),
            date: Date(),
            category: .food,
            splitType: .equal,
            splits: [
                ExpenseSplit(
                    id: "test-split-id",
                    user: User(id: "test-user-id", firstName: "Test", lastName: "User", email: "test@example.com"),
                    amount: 100.0,
                    percentage: nil,
                    shares: nil,
                    settled: false
                )
            ],
            receipt: nil,
            flags: nil,
            comments: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func createMockExpenseData() -> ExpenseCreateData {
        return ExpenseCreateData(
            group: "test-group-id",
            description: "Test Expense",
            amount: 100.0,
            currency: "PLN",
            paidBy: "test-user-id",
            date: Date(),
            category: "food",
            splitType: "equal",
            splits: [
                ExpenseSplitCreateData(
                    user: "test-user-id",
                    amount: 100.0,
                    percentage: nil,
                    shares: nil
                )
            ],
            flags: nil
        )
    }
}

// Mock network service specific for expense tests
class MockNetworkServiceForExpenses: NetworkServiceProtocol {
    var mockData: Data?
    var mockError: Error?
    
    func request<T: Decodable>(_ endpoint: APIEndpoint) -> AnyPublisher<T, Error> {
        if let error = mockError {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        guard let data = mockData else {
            return Fail(error: APIError.invalidResponse).eraseToAnyPublisher()
        }
        
        do {
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            let decodedObject = try decoder.decode(T.self, from: data)
            return Just(decodedObject)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: APIError.decodingError).eraseToAnyPublisher()
        }
    }
}