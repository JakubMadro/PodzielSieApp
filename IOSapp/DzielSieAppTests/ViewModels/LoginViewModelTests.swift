//
//  LoginViewModelTests.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//


import XCTest
import Combine
@testable import DzielSieApp

final class LoginViewModelTests: XCTestCase {
    
    var viewModel: LoginViewModel!
    var mockNetworkService: MockNetworkService!
    var mockAuthService: MockAuthService!
    var mockAppState: AppState!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        mockAuthService = MockAuthService()
        mockAppState = AppState()
        viewModel = LoginViewModel(
            appState: mockAppState,
            networkService: mockNetworkService,
            authService: mockAuthService
        )
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        viewModel = nil
        mockNetworkService = nil
        mockAuthService = nil
        mockAppState = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testLoginViewModel_EmptyCredentials_InvalidForm() {
        // Given
        viewModel.email = ""
        viewModel.password = ""
        
        // Then
        XCTAssertFalse(viewModel.isFormValid)
    }
    
    func testLoginViewModel_InvalidEmail_InvalidForm() {
        // Given
        viewModel.email = "invalid-email"
        viewModel.password = "password123"
        
        // Then
        XCTAssertFalse(viewModel.isFormValid)
    }
    
    func testLoginViewModel_ValidCredentials_ValidForm() {
        // Given
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        
        // Then
        XCTAssertTrue(viewModel.isFormValid)
    }
    
    func testLogin_Success() {
        // Given
        let mockUser = User(id: "1", firstName: "Test", lastName: "User", email: "test@example.com")
        let mockResponse = LoginViewModel.LoginResponse(
            success: true,
            message: "Login successful",
            token: "test-token",
            refreshToken: "test-refresh-token",
            user: mockUser
        )
        
        mockNetworkService.loginResponse = .success(mockResponse)
        
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        
        // When
        let expectation = XCTestExpectation(description: "Login success")
        viewModel.login()
        
        // Wait a bit for the async operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertTrue(mockAppState.isAuthenticated)
        XCTAssertEqual(mockAppState.currentUser?.id, mockUser.id)
        
        // Verify auth service was called
        XCTAssertEqual(mockAuthService.savedToken, "test-token")
        XCTAssertEqual(mockAuthService.savedRefreshToken, "test-refresh-token")
        XCTAssertEqual(mockAuthService.savedUser?.id, mockUser.id)
    }
    
    func testLogin_Failure() {
        // Given
        let expectedError = APIError.serverError(message: "Invalid credentials")
        mockNetworkService.loginResponse = .failure(expectedError)
        
        viewModel.email = "test@example.com"
        viewModel.password = "wrong-password"
        
        // When
        let expectation = XCTestExpectation(description: "Login failure")
        viewModel.login()
        
        // Wait a bit for the async operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.error, expectedError.localizedDescription)
        XCTAssertFalse(mockAppState.isAuthenticated)
        XCTAssertNil(mockAppState.currentUser)
    }
    
    func testLogin_InvalidForm_NoNetworkCall() {
        // Given
        viewModel.email = "invalid-email"
        viewModel.password = "password123"
        
        // When
        viewModel.login()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(mockNetworkService.loginCallCount, 0)
    }
}

// Mock services for testing
class MockNetworkService: NetworkServiceProtocol {
    var loginResponse: Result<LoginViewModel.LoginResponse, Error> = .success(
        LoginViewModel.LoginResponse(success: true, message: nil, token: nil, refreshToken: nil, user: nil)
    )
    var loginCallCount = 0
    
    func request<T: Decodable>(_ endpoint: APIEndpoint) -> AnyPublisher<T, Error> {
        switch endpoint {
        case .login(let email, let password):
            loginCallCount += 1
            return loginResponse
                .map { $0 as! T }
                .publisher
                .delay(for: .milliseconds(10), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        default:
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
    }
}

class MockAuthService: AuthServiceProtocol {
    var savedToken: String?
    var savedRefreshToken: String?
    var savedUser: User?
    
    func saveAuthData(token: String?, refreshToken: String?, user: User?) {
        savedToken = token
        savedRefreshToken = refreshToken
        savedUser = user
    }
}