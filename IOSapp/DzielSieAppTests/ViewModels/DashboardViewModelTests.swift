//
//  DashboardViewModelTests.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//

import XCTest
import Combine
@testable import DzielSieApp

final class DashboardViewModelTests: XCTestCase {
    
    var viewModel: DashboardViewModel!
    var mockDashboardService: MockDashboardServiceForVM!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockDashboardService = MockDashboardServiceForVM()
        viewModel = DashboardViewModel(dashboardService: mockDashboardService)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        viewModel = nil
        mockDashboardService = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testFetchRecentActivities_Success() {
        // Given
        let mockActivities = [
            createMockActivity(id: "1", title: "Test Activity 1", type: .newExpense),
            createMockActivity(id: "2", title: "Test Activity 2", type: .addedToGroup),
            createMockActivity(id: "3", title: "Test Activity 3", type: .settledExpense)
        ]
        mockDashboardService.fetchRecentActivitiesResult = .success(mockActivities)
        
        // When
        let expectation = XCTestExpectation(description: "Fetch recent activities")
        viewModel.fetchRecentActivities()
        
        // Oczekiwanie na operację asynchroniczną
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        // Sprawdzenie wyników
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.activities.count, 3)
        XCTAssertEqual(viewModel.activities.first?.title, "Test Activity 1")
        XCTAssertEqual(viewModel.activities.first?.type, .newExpense)
    }
    
    func testFetchRecentActivities_EmptyResponse() {
        // Given
        mockDashboardService.fetchRecentActivitiesResult = .success([])
        
        // When
        let expectation = XCTestExpectation(description: "Fetch empty activities")
        viewModel.fetchRecentActivities()
        
        // Oczekiwanie na operację asynchroniczną
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        // Sprawdzenie wyników
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.activities.count, 0)
    }
    
    func testFetchRecentActivities_NetworkError() {
        // Given
        let expectedError = APIError.networkError(URLError(.notConnectedToInternet))
        mockDashboardService.fetchRecentActivitiesResult = .failure(expectedError)
        
        // When
        let expectation = XCTestExpectation(description: "Fetch activities network error")
        viewModel.fetchRecentActivities()
        
        // Oczekiwanie na operację asynchroniczną
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        // Sprawdzenie wyników
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.error, expectedError.localizedDescription)
        XCTAssertEqual(viewModel.activities.count, 0)
    }
    
    func testFetchRecentActivities_ServerError() {
        // Given
        let expectedError = APIError.serverError(message: "Internal server error")
        mockDashboardService.fetchRecentActivitiesResult = .failure(expectedError)
        
        // When
        let expectation = XCTestExpectation(description: "Fetch activities server error")
        viewModel.fetchRecentActivities()
        
        // Oczekiwanie na operację asynchroniczną
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        // Sprawdzenie wyników
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.error, expectedError.localizedDescription)
        XCTAssertEqual(viewModel.activities.count, 0)
    }
    
    func testFetchRecentActivities_UnknownError() {
        // Given
        let expectedError = NSError(domain: "TestError", code: 999, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        mockDashboardService.fetchRecentActivitiesResult = .failure(expectedError)
        
        // When
        let expectation = XCTestExpectation(description: "Fetch activities unknown error")
        viewModel.fetchRecentActivities()
        
        // Oczekiwanie na operację asynchroniczną
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        // Sprawdzenie wyników
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.error?.contains("Nieznany błąd") ?? false)
        XCTAssertEqual(viewModel.activities.count, 0)
    }
    
    func testFetchRecentActivities_LoadingState() {
        // Given
        let mockActivities = [createMockActivity(id: "1", title: "Test Activity", type: .newExpense)]
        mockDashboardService.fetchRecentActivitiesResult = .success(mockActivities)
        
        // When
        viewModel.fetchRecentActivities()
        
        // Sprawdzenie wyników (check loading state immediately)
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        
        // Wait for completion
        let expectation = XCTestExpectation(description: "Fetch activities loading")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testGetMockActivities_StaticMethod() {
        // When
        let mockActivities = DashboardViewModel.getMockActivities()
        
        // Sprawdzenie wyników
        XCTAssertEqual(mockActivities.count, 3)
        XCTAssertEqual(mockActivities[0].type, .newExpense)
        XCTAssertEqual(mockActivities[1].type, .newExpense)
        XCTAssertEqual(mockActivities[2].type, .addedToGroup)
        
        XCTAssertNotNil(mockActivities[0].amount)
        XCTAssertNotNil(mockActivities[1].amount)
        XCTAssertNil(mockActivities[2].amount)
        
        XCTAssertEqual(mockActivities[0].currency, "PLN")
        XCTAssertEqual(mockActivities[1].currency, "PLN")
        XCTAssertEqual(mockActivities[2].currency, "PLN")
    }
    
    func testInitialState() {
        // When creating a new view model
        let newViewModel = DashboardViewModel(dashboardService: mockDashboardService)
        
        // Sprawdzenie wyników
        XCTAssertEqual(newViewModel.activities.count, 0)
        XCTAssertFalse(newViewModel.isLoading)
        XCTAssertNil(newViewModel.error)
    }
    
    func testMultipleFetchCalls() {
        // Given
        let mockActivities1 = [createMockActivity(id: "1", title: "Activity 1", type: .newExpense)]
        let mockActivities2 = [createMockActivity(id: "2", title: "Activity 2", type: .addedToGroup)]
        
        // When - First fetch
        mockDashboardService.fetchRecentActivitiesResult = .success(mockActivities1)
        viewModel.fetchRecentActivities()
        
        let expectation1 = XCTestExpectation(description: "First fetch")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1.0)
        
        // Sprawdzenie wyników - Check first results
        XCTAssertEqual(viewModel.activities.count, 1)
        XCTAssertEqual(viewModel.activities.first?.title, "Activity 1")
        
        // When - Second fetch
        mockDashboardService.fetchRecentActivitiesResult = .success(mockActivities2)
        viewModel.fetchRecentActivities()
        
        let expectation2 = XCTestExpectation(description: "Second fetch")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)
        
        // Sprawdzenie wyników - Check second results
        XCTAssertEqual(viewModel.activities.count, 1)
        XCTAssertEqual(viewModel.activities.first?.title, "Activity 2")
    }
    
    // Metoda pomocnicza do tworzenia testowej aktywności
    private func createMockActivity(
        id: String,
        title: String,
        type: ActivityType,
        subtitle: String = "Test subtitle",
        amount: Double? = 100.0,
        currency: String = "PLN"
    ) -> Activity {
        return Activity(
            id: id,
            type: type,
            title: title,
            subtitle: subtitle,
            amount: amount,
            currency: currency,
            date: Date(),
            iconName: "dollarsign.circle",
            groupId: "test-group-id",
            expenseId: "test-expense-id"
        )
    }
}

// Mockowy DashboardService dla testów DashboardViewModel
class MockDashboardServiceForVM: DashboardServiceProtocol {
    var fetchRecentActivitiesResult: Result<[Activity], Error> = .success([])
    
    func fetchRecentActivities(limit: Int) -> AnyPublisher<[Activity], Error> {
        return fetchRecentActivitiesResult.publisher
            .delay(for: .milliseconds(10), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}