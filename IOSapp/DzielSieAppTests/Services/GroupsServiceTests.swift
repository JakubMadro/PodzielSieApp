//
//  GroupsServiceTests.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//

import XCTest
import Combine
@testable import DzielSieApp

final class GroupsServiceTests: XCTestCase {
    
    var groupsService: GroupsService!
    var mockNetworkService: MockNetworkServiceForGroups!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkServiceForGroups()
        groupsService = GroupsService(networkService: mockNetworkService)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        groupsService = nil
        mockNetworkService = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testFetchGroups_Success() {
        // Dane testowe
        let mockGroups = [createMockGroup(), createMockGroup(id: "group-2", name: "Test Group 2")]
        let mockResponse = GroupsResponse(success: true, groups: mockGroups)
        mockNetworkService.mockData = try! JSONEncoder().encode(mockResponse)
        
        // Wykonanie testu
        let expectation = XCTestExpectation(description: "Pobranie grup")
        var resultGroups: [Group]?
        var resultError: Error?
        
        groupsService.fetchGroups()
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { groups in
                resultGroups = groups
            })
            .store(in: &cancellables)
        
        // Sprawdzenie wyników
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertNotNil(resultGroups)
        XCTAssertEqual(resultGroups?.count, 2)
        XCTAssertEqual(resultGroups?.first?.name, "Test Group")
    }
    
    func testFetchGroupDetails_Success() {
        // Dane testowe
        let mockGroup = createMockGroup()
        let mockResponse = GroupResponse(success: true, group: mockGroup)
        mockNetworkService.mockData = try! JSONEncoder().encode(mockResponse)
        
        // Wykonanie testu
        let expectation = XCTestExpectation(description: "Pobranie szczegółów grupy")
        var resultGroup: Group?
        var resultError: Error?
        
        groupsService.fetchGroupDetails(groupId: "test-group-id")
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { group in
                resultGroup = group
            })
            .store(in: &cancellables)
        
        // Sprawdzenie wyników
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertNotNil(resultGroup)
        XCTAssertEqual(resultGroup?.id, mockGroup.id)
        XCTAssertEqual(resultGroup?.name, mockGroup.name)
    }
    
    func testCreateGroup_Success() {
        // Dane testowe
        let mockGroup = createMockGroup()
        let mockResponse = GroupResponse(success: true, group: mockGroup)
        mockNetworkService.mockData = try! JSONEncoder().encode(mockResponse)
        
        // Wykonanie testu
        let expectation = XCTestExpectation(description: "Utworzenie grupy")
        var resultGroup: Group?
        var resultError: Error?
        
        groupsService.createGroup(name: "Test Group", description: "Test Description", defaultCurrency: "PLN")
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { group in
                resultGroup = group
            })
            .store(in: &cancellables)
        
        // Sprawdzenie wyników
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertNotNil(resultGroup)
        XCTAssertEqual(resultGroup?.name, "Test Group")
    }
    
    func testAddMember_Success() {
        // Dane testowe
        let mockGroup = createMockGroup()
        let mockResponse = GroupResponse(success: true, group: mockGroup)
        mockNetworkService.mockData = try! JSONEncoder().encode(mockResponse)
        
        // Wykonanie testu
        let expectation = XCTestExpectation(description: "Dodanie członka")
        var resultGroup: Group?
        var resultError: Error?
        
        groupsService.addMember(groupId: "test-group-id", email: "new@example.com", role: "member")
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { group in
                resultGroup = group
            })
            .store(in: &cancellables)
        
        // Sprawdzenie wyników
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertNotNil(resultGroup)
        XCTAssertEqual(resultGroup?.id, mockGroup.id)
    }
    
    func testDeleteGroup_Success() {
        // Dane testowe
        let mockResponse = GroupDeleteResponse(success: true, message: "Grupa usunięta")
        mockNetworkService.mockData = try! JSONEncoder().encode(mockResponse)
        
        // Wykonanie testu
        let expectation = XCTestExpectation(description: "Usunięcie grupy")
        var resultSuccess: Bool?
        var resultError: Error?
        
        groupsService.deleteGroup(groupId: "test-group-id")
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { success in
                resultSuccess = success
            })
            .store(in: &cancellables)
        
        // Sprawdzenie wyników
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertNotNil(resultSuccess)
        XCTAssertTrue(resultSuccess!)
    }
    
    func testFetchUserBalance_Success() {
        // Dane testowe
        let mockBalance = UserBalanceDetails(
            totalBalance: 100.0,
            totalOwed: 50.0,
            totalOwing: 25.0,
            currency: "PLN",
            balanceBreakdown: []
        )
        let mockResponse = UserBalanceResponse(success: true, balance: mockBalance)
        mockNetworkService.mockData = try! JSONEncoder().encode(mockResponse)
        
        // Wykonanie testu
        let expectation = XCTestExpectation(description: "Pobranie balansu użytkownika")
        var resultBalance: UserBalanceDetails?
        var resultError: Error?
        
        groupsService.fetchUserBalance(groupId: "test-group-id")
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { balance in
                resultBalance = balance
            })
            .store(in: &cancellables)
        
        // Sprawdzenie wyników
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertNotNil(resultBalance)
        XCTAssertEqual(resultBalance?.totalBalance, 100.0)
        XCTAssertEqual(resultBalance?.currency, "PLN")
    }
    
    func testFetchGroups_NetworkError() {
        // Dane testowe
        let expectedError = APIError.networkError(URLError(.notConnectedToInternet))
        mockNetworkService.mockError = expectedError
        
        // Wykonanie testu
        let expectation = XCTestExpectation(description: "Błąd sieci przy pobieraniu grup")
        var resultError: Error?
        
        groupsService.fetchGroups()
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        // Sprawdzenie wyników
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(resultError)
    }
    
    // Metoda pomocnicza do tworzenia testowej grupy
    private func createMockGroup(id: String = "test-group-id", name: String = "Test Group") -> Group {
        return Group(
            id: id,
            name: name,
            description: "Test description",
            defaultCurrency: "PLN",
            owner: User(id: "owner-id", firstName: "Owner", lastName: "User", email: "owner@example.com"),
            members: [
                GroupMember(
                    id: "member-1",
                    user: User(id: "user-1", firstName: "Test", lastName: "User", email: "test@example.com"),
                    role: "member",
                    joinedAt: Date()
                )
            ],
            createdAt: Date(),
            updatedAt: Date(),
            isArchived: false
        )
    }
}

// Mockowy serwis sieciowy dla testów grup
class MockNetworkServiceForGroups: NetworkServiceProtocol {
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

// Modele odpowiedzi dla testów
struct GroupsResponse: Codable {
    let success: Bool
    let groups: [Group]
}

struct GroupResponse: Codable {
    let success: Bool
    let group: Group
}

struct GroupDeleteResponse: Codable {
    let success: Bool
    let message: String
}

struct UserBalanceResponse: Codable {
    let success: Bool
    let balance: UserBalanceDetails
}