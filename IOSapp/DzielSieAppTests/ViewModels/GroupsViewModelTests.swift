//
//  GroupsViewModelTests.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//

import XCTest
import Combine
@testable import DzielSieApp

final class GroupsViewModelTests: XCTestCase {
    
    var viewModel: GroupsViewModel!
    var mockGroupsService: MockGroupsServiceForGroupsVM!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockGroupsService = MockGroupsServiceForGroupsVM()
        viewModel = GroupsViewModel(groupsService: mockGroupsService)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        viewModel = nil
        mockGroupsService = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testFetchGroups_Success() {
        // Given
        let mockGroups = [
            createMockGroup(id: "1", name: "Test Group 1"),
            createMockGroup(id: "2", name: "Test Group 2")
        ]
        mockGroupsService.fetchGroupsResult = .success(mockGroups)
        
        // When
        let expectation = XCTestExpectation(description: "Fetch groups")
        viewModel.fetchGroups()
        
        // Oczekiwanie na operację asynchroniczną
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        // Sprawdzenie wyników
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.groups.count, 2)
        XCTAssertEqual(viewModel.groups.first?.name, "Test Group 1")
    }
    
    func testFetchGroups_Failure() {
        // Given
        let expectedError = APIError.serverError(message: "Failed to fetch groups")
        mockGroupsService.fetchGroupsResult = .failure(expectedError)
        
        // When
        let expectation = XCTestExpectation(description: "Fetch groups error")
        viewModel.fetchGroups()
        
        // Oczekiwanie na operację asynchroniczną
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        // Sprawdzenie wyników
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.error, expectedError.localizedDescription)
        XCTAssertEqual(viewModel.groups.count, 0)
    }
    
    func testArchiveGroup_Success() {
        // Given
        let mockGroup = createMockGroup(id: "1", name: "Test Group")
        viewModel.groups = [mockGroup]
        
        let archivedGroup = createMockGroup(id: "1", name: "Test Group", isArchived: true)
        mockGroupsService.archiveGroupResult = .success(archivedGroup)
        
        // When
        let expectation = XCTestExpectation(description: "Archive group")
        viewModel.archiveGroup(groupId: "1", archive: true)
        
        // Oczekiwanie na operację asynchroniczną
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        // Sprawdzenie wyników
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertTrue(viewModel.groups.first?.isArchived ?? false)
    }
    
    func testDeleteGroup_Success() {
        // Given
        let mockGroup = createMockGroup(id: "1", name: "Test Group")
        viewModel.groups = [mockGroup]
        mockGroupsService.deleteGroupResult = .success(true)
        
        // When
        let expectation = XCTestExpectation(description: "Delete group")
        viewModel.deleteGroup(groupId: "1")
        
        // Oczekiwanie na operację asynchroniczną
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        // Sprawdzenie wyników
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.groups.count, 0)
        XCTAssertFalse(viewModel.showConfirmationDialog)
    }
    
    func testDeleteGroup_Failure() {
        // Given
        let mockGroup = createMockGroup(id: "1", name: "Test Group")
        viewModel.groups = [mockGroup]
        
        let expectedError = APIError.serverError(message: "Failed to delete group")
        mockGroupsService.deleteGroupResult = .failure(expectedError)
        
        // When
        let expectation = XCTestExpectation(description: "Delete group error")
        viewModel.deleteGroup(groupId: "1")
        
        // Oczekiwanie na operację asynchroniczną
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        // Sprawdzenie wyników
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.error, expectedError.localizedDescription)
        XCTAssertEqual(viewModel.groups.count, 1) // Group should still be there
        XCTAssertFalse(viewModel.showConfirmationDialog)
    }
    
    func testSelectGroup() {
        // Given
        let mockGroup = createMockGroup(id: "1", name: "Test Group")
        
        // When
        viewModel.selectGroup(mockGroup)
        
        // Sprawdzenie wyników
        XCTAssertEqual(viewModel.selectedGroup?.id, mockGroup.id)
        XCTAssertTrue(viewModel.showCreateGroupView)
    }
    
    func testSelectGroupForAddingMember() {
        // Given
        let mockGroup = createMockGroup(id: "1", name: "Test Group")
        
        // When
        viewModel.selectGroupForAddingMember(mockGroup)
        
        // Sprawdzenie wyników
        XCTAssertEqual(viewModel.selectedGroup?.id, mockGroup.id)
        XCTAssertTrue(viewModel.showAddMemberView)
    }
    
    func testGroupCreated_DelegateMethod() {
        // Given
        let newGroup = createMockGroup(id: "new", name: "New Group")
        viewModel.showCreateGroupView = true
        
        // When
        viewModel.groupCreated(newGroup)
        
        // Sprawdzenie wyników
        XCTAssertEqual(viewModel.groups.count, 1)
        XCTAssertEqual(viewModel.groups.first?.id, newGroup.id)
        XCTAssertFalse(viewModel.showCreateGroupView)
    }
    
    func testMemberAdded_DelegateMethod() {
        // Given
        let originalGroup = createMockGroup(id: "1", name: "Test Group")
        viewModel.groups = [originalGroup]
        viewModel.showAddMemberView = true
        
        let updatedGroup = createMockGroup(id: "1", name: "Test Group", memberCount: 2)
        
        // When
        viewModel.memberAdded(to: updatedGroup)
        
        // Sprawdzenie wyników
        XCTAssertEqual(viewModel.groups.count, 1)
        XCTAssertEqual(viewModel.groups.first?.members.count, 2)
        XCTAssertFalse(viewModel.showAddMemberView)
    }
    
    func testRefreshGroups_NotificationObserver() {
        // Given
        let mockGroups = [createMockGroup(id: "1", name: "Test Group")]
        mockGroupsService.fetchGroupsResult = .success(mockGroups)
        
        // When
        let expectation = XCTestExpectation(description: "Refresh groups")
        NotificationCenter.default.post(name: NSNotification.Name("GroupCreated"), object: nil)
        
        // Oczekiwanie na operację asynchroniczną
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        // Sprawdzenie wyników
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.groups.count, 1)
    }
    
    func testHandleError_UnauthorizedError() {
        // Given
        let expectedError = APIError.unauthorized
        mockGroupsService.fetchGroupsResult = .failure(expectedError)
        
        // When
        let expectation = XCTestExpectation(description: "Handle unauthorized error")
        viewModel.fetchGroups()
        
        // Oczekiwanie na operację asynchroniczną
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        // Sprawdzenie wyników
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.error, expectedError.localizedDescription)
        // Note: We can't easily test AppState.shared.logout() without mocking AppState
    }
    
    // Metoda pomocnicza do tworzenia testowej grupy
    private func createMockGroup(id: String, name: String, isArchived: Bool = false, memberCount: Int = 1) -> Group {
        var members: [GroupMember] = []
        for i in 0..<memberCount {
            members.append(GroupMember(
                id: "member-\(i)",
                user: User(id: "user-\(i)", firstName: "User", lastName: "\(i)", email: "user\(i)@example.com"),
                role: "member",
                joinedAt: Date()
            ))
        }
        
        return Group(
            id: id,
            name: name,
            description: "Test description",
            defaultCurrency: "PLN",
            owner: User(id: "owner-id", firstName: "Owner", lastName: "User", email: "owner@example.com"),
            members: members,
            createdAt: Date(),
            updatedAt: Date(),
            isArchived: isArchived
        )
    }
}

// Mockowy GroupsService dla testów GroupsViewModel
class MockGroupsServiceForGroupsVM: GroupsServiceProtocol {
    var fetchGroupsResult: Result<[Group], Error> = .success([])
    var fetchGroupDetailsResult: Result<Group, Error> = .success(
        Group(
            id: "test-id",
            name: "Test Group",
            description: "Test description",
            defaultCurrency: "PLN",
            owner: User(id: "owner-id", firstName: "Owner", lastName: "User", email: "owner@example.com"),
            members: [],
            createdAt: Date(),
            updatedAt: Date(),
            isArchived: false
        )
    )
    var fetchUserBalanceResult: Result<UserBalanceDetails, Error> = .success(
        UserBalanceDetails(
            totalBalance: 0.0,
            totalOwed: 0.0,
            totalOwing: 0.0,
            currency: "PLN",
            balanceBreakdown: []
        )
    )
    var createGroupResult: Result<Group, Error> = .success(
        Group(
            id: "new-id",
            name: "New Group",
            description: "New description",
            defaultCurrency: "PLN",
            owner: User(id: "owner-id", firstName: "Owner", lastName: "User", email: "owner@example.com"),
            members: [],
            createdAt: Date(),
            updatedAt: Date(),
            isArchived: false
        )
    )
    var updateGroupResult: Result<Group, Error> = .success(
        Group(
            id: "test-id",
            name: "Updated Group",
            description: "Updated description",
            defaultCurrency: "PLN",
            owner: User(id: "owner-id", firstName: "Owner", lastName: "User", email: "owner@example.com"),
            members: [],
            createdAt: Date(),
            updatedAt: Date(),
            isArchived: false
        )
    )
    var addMemberResult: Result<Group, Error> = .success(
        Group(
            id: "test-id",
            name: "Test Group",
            description: "Test description",
            defaultCurrency: "PLN",
            owner: User(id: "owner-id", firstName: "Owner", lastName: "User", email: "owner@example.com"),
            members: [],
            createdAt: Date(),
            updatedAt: Date(),
            isArchived: false
        )
    )
    var removeMemberResult: Result<Group, Error> = .success(
        Group(
            id: "test-id",
            name: "Test Group",
            description: "Test description",
            defaultCurrency: "PLN",
            owner: User(id: "owner-id", firstName: "Owner", lastName: "User", email: "owner@example.com"),
            members: [],
            createdAt: Date(),
            updatedAt: Date(),
            isArchived: false
        )
    )
    var updateMemberRoleResult: Result<Group, Error> = .success(
        Group(
            id: "test-id",
            name: "Test Group",
            description: "Test description",
            defaultCurrency: "PLN",
            owner: User(id: "owner-id", firstName: "Owner", lastName: "User", email: "owner@example.com"),
            members: [],
            createdAt: Date(),
            updatedAt: Date(),
            isArchived: false
        )
    )
    var archiveGroupResult: Result<Group, Error> = .success(
        Group(
            id: "test-id",
            name: "Test Group",
            description: "Test description",
            defaultCurrency: "PLN",
            owner: User(id: "owner-id", firstName: "Owner", lastName: "User", email: "owner@example.com"),
            members: [],
            createdAt: Date(),
            updatedAt: Date(),
            isArchived: true
        )
    )
    var deleteGroupResult: Result<Bool, Error> = .success(true)
    
    func fetchGroups() -> AnyPublisher<[Group], Error> {
        return result(fetchGroupsResult)
    }
    
    func fetchGroupDetails(groupId: String) -> AnyPublisher<Group, Error> {
        return result(fetchGroupDetailsResult)
    }
    
    func fetchUserBalance(groupId: String) -> AnyPublisher<UserBalanceDetails, Error> {
        return result(fetchUserBalanceResult)
    }
    
    func createGroup(name: String, description: String?, defaultCurrency: String?) -> AnyPublisher<Group, Error> {
        return result(createGroupResult)
    }
    
    func updateGroup(groupId: String, name: String?, description: String?, defaultCurrency: String?) -> AnyPublisher<Group, Error> {
        return result(updateGroupResult)
    }
    
    func addMember(groupId: String, email: String, role: String?) -> AnyPublisher<Group, Error> {
        return result(addMemberResult)
    }
    
    func removeMember(groupId: String, userId: String) -> AnyPublisher<Group, Error> {
        return result(removeMemberResult)
    }
    
    func updateMemberRole(groupId: String, userId: String, role: String) -> AnyPublisher<Group, Error> {
        return result(updateMemberRoleResult)
    }
    
    func archiveGroup(groupId: String, archive: Bool) -> AnyPublisher<Group, Error> {
        return result(archiveGroupResult)
    }
    
    func deleteGroup(groupId: String) -> AnyPublisher<Bool, Error> {
        return result(deleteGroupResult)
    }
    
    private func result<T>(_ result: Result<T, Error>) -> AnyPublisher<T, Error> {
        return result.publisher
            .delay(for: .milliseconds(10), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}