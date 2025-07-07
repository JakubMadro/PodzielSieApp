//
//  DashboardServiceTests.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//

import XCTest
import Combine
@testable import DzielSieApp

final class DashboardServiceTests: XCTestCase {
    
    var dashboardService: DashboardService!
    var mockNetworkService: MockNetworkServiceForDashboard!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkServiceForDashboard()
        dashboardService = DashboardService(networkService: mockNetworkService)
        cancellables = Set<AnyCancellable>()
        
        // Ustaw token autoryzacyjny dla testów
        UserDefaults.standard.set("test-token", forKey: "authToken")
    }
    
    override func tearDown() {
        dashboardService = nil
        mockNetworkService = nil
        cancellables = nil
        UserDefaults.standard.removeObject(forKey: "authToken")
        super.tearDown()
    }
    
    func testFetchRecentActivities_Success() {
        // Dane testowe
        let mockActivities = [
            createMockActivity(id: "1", type: "newExpense", title: "Test Expense 1"),
            createMockActivity(id: "2", type: "addedToGroup", title: "Added to Group"),
            createMockActivity(id: "3", type: "settledExpense", title: "Settled Expense")
        ]
        
        let mockResponse = MockActivitiesResponse(
            success: true,
            activities: mockActivities.map { activity in
                MockActivityDTO(
                    id: activity.id,
                    type: activity.type.rawValue,
                    title: activity.title,
                    subtitle: activity.subtitle,
                    amount: activity.amount,
                    currency: activity.currency,
                    date: activity.date,
                    iconName: activity.iconName,
                    groupId: activity.groupId,
                    expenseId: activity.expenseId
                )
            }
        )
        
        mockNetworkService.mockData = try! JSONEncoder().encode(mockResponse)
        
        // Wykonanie testu
        let expectation = XCTestExpectation(description: "Pobranie najnowszych aktywności")
        var resultActivities: [Activity]?
        var resultError: Error?
        
        dashboardService.fetchRecentActivities(limit: 5)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { activities in
                resultActivities = activities
            })
            .store(in: &cancellables)
        
        // Sprawdzenie wyników
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertNotNil(resultActivities)
        XCTAssertEqual(resultActivities?.count, 3)
        XCTAssertEqual(resultActivities?.first?.title, "Test Expense 1")
        XCTAssertEqual(resultActivities?.first?.type, .newExpense)
    }
    
    func testFetchRecentActivities_EmptyResponse() {
        // Given
        let mockResponse = MockActivitiesResponse(success: true, activities: [])
        mockNetworkService.mockData = try! JSONEncoder().encode(mockResponse)
        
        // When
        let expectation = XCTestExpectation(description: "Fetch empty activities")
        var resultActivities: [Activity]?
        var resultError: Error?
        
        dashboardService.fetchRecentActivities(limit: 5)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { activities in
                resultActivities = activities
            })
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertNotNil(resultActivities)
        XCTAssertEqual(resultActivities?.count, 0)
    }
    
    func testFetchRecentActivities_NetworkError() {
        // Given
        let expectedError = APIError.networkError(URLError(.notConnectedToInternet))
        mockNetworkService.mockError = expectedError
        
        // When
        let expectation = XCTestExpectation(description: "Fetch activities network error")
        var resultError: Error?
        
        dashboardService.fetchRecentActivities(limit: 5)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(resultError)
    }
    
    func testFetchRecentActivities_UnauthorizedError() {
        // Given
        mockNetworkService.mockHttpStatusCode = 401
        
        // When
        let expectation = XCTestExpectation(description: "Fetch activities unauthorized")
        var resultError: Error?
        
        dashboardService.fetchRecentActivities(limit: 5)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(resultError)
        if let apiError = resultError as? APIError {
            switch apiError {
            case .unauthorized:
                XCTAssert(true, "Correctly identified unauthorized error")
            default:
                XCTFail("Expected unauthorized error, got \(apiError)")
            }
        } else {
            XCTFail("Expected APIError, got \(String(describing: resultError))")
        }
    }
    
    func testFetchRecentActivities_DecodingError() {
        // Given
        let invalidJSON = "invalid json"
        mockNetworkService.mockData = invalidJSON.data(using: .utf8)
        
        // When
        let expectation = XCTestExpectation(description: "Fetch activities decoding error")
        var resultError: Error?
        
        dashboardService.fetchRecentActivities(limit: 5)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(resultError)
    }
    
    func testFetchRecentActivities_CustomLimit() {
        // Given
        let mockResponse = MockActivitiesResponse(success: true, activities: [])
        mockNetworkService.mockData = try! JSONEncoder().encode(mockResponse)
        
        // When
        let expectation = XCTestExpectation(description: "Fetch activities with custom limit")
        var resultActivities: [Activity]?
        
        dashboardService.fetchRecentActivities(limit: 10)
            .sink(receiveCompletion: { _ in
                expectation.fulfill()
            }, receiveValue: { activities in
                resultActivities = activities
            })
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(resultActivities)
        // Verify that the limit parameter is used correctly
        XCTAssertTrue(mockNetworkService.lastRequestURL?.absoluteString.contains("limit=10") ?? false)
    }
    
    // Helper method to create mock activity
    private func createMockActivity(
        id: String,
        type: String,
        title: String,
        subtitle: String = "Test subtitle",
        amount: Double? = 100.0,
        currency: String = "PLN"
    ) -> Activity {
        let activityType: ActivityType
        switch type {
        case "newExpense": activityType = .newExpense
        case "addedToGroup": activityType = .addedToGroup
        case "settledExpense": activityType = .settledExpense
        case "groupCreated": activityType = .groupCreated
        case "memberAdded": activityType = .memberAdded
        default: activityType = .newExpense
        }
        
        return Activity(
            id: id,
            type: activityType,
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

// Mock network service specific for dashboard tests
class MockNetworkServiceForDashboard: NetworkServiceProtocol {
    var mockData: Data?
    var mockError: Error?
    var mockHttpStatusCode: Int = 200
    var lastRequestURL: URL?
    
    func request<T: Decodable>(_ endpoint: APIEndpoint) -> AnyPublisher<T, Error> {
        // This is a simplified mock that doesn't fully implement the DashboardService's direct URL approach
        // In a real scenario, you'd want to create a protocol for URL session or use dependency injection
        
        if let error = mockError {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        if mockHttpStatusCode == 401 {
            return Fail(error: APIError.unauthorized).eraseToAnyPublisher()
        }
        
        if mockHttpStatusCode >= 400 {
            return Fail(error: APIError.serverError(message: "HTTP \(mockHttpStatusCode)")).eraseToAnyPublisher()
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

// Mock response structures for dashboard tests
struct MockActivitiesResponse: Codable {
    let success: Bool
    let activities: [MockActivityDTO]
}

struct MockActivityDTO: Codable {
    let id: String
    let type: String
    let title: String
    let subtitle: String
    let amount: Double?
    let currency: String
    let date: Date
    let iconName: String
    let groupId: String?
    let expenseId: String?
    
    init(id: String, type: String, title: String, subtitle: String, amount: Double?, currency: String, date: Date, iconName: String, groupId: String?, expenseId: String?) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
        self.currency = currency
        self.date = date
        self.iconName = iconName
        self.groupId = groupId
        self.expenseId = expenseId
    }
}