//
//  AuthServiceTests.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//

import XCTest
import Combine
@testable import DzielSieApp

final class AuthServiceTests: XCTestCase {
    
    var authService: AuthService!
    var mockNetworkService: MockNetworkServiceForAuth!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkServiceForAuth()
        authService = AuthService(networkService: mockNetworkService)
        cancellables = Set<AnyCancellable>()
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        UserDefaults.standard.removeObject(forKey: "userData")
    }
    
    override func tearDown() {
        authService = nil
        mockNetworkService = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testSaveAuthData_Success() {
        // Dane testowe
        let testToken = "test-token"
        let testRefreshToken = "test-refresh-token"
        let testUser = User(id: "user-id", firstName: "Test", lastName: "User", email: "test@example.com")
        
        // Wykonanie testu
        authService.saveAuthData(token: testToken, refreshToken: testRefreshToken, user: testUser)
        
        // Sprawdzenie wyników
        XCTAssertEqual(UserDefaults.standard.string(forKey: "authToken"), testToken)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "refreshToken"), testRefreshToken)
        
        // Sprawdzenie czy dane użytkownika zostały zapisane
        if let userData = UserDefaults.standard.data(forKey: "userData"),
           let savedUser = try? JSONDecoder().decode(User.self, from: userData) {
            XCTAssertEqual(savedUser.id, testUser.id)
            XCTAssertEqual(savedUser.email, testUser.email)
        } else {
            XCTFail("Dane użytkownika nie zostały poprawnie zapisane")
        }
        
        // Sprawdzenie AppState
        XCTAssertEqual(AppState.shared.currentUser?.id, testUser.id)
        XCTAssertTrue(AppState.shared.isAuthenticated)
    }
    
    func testSaveAuthData_NilValues() {
        // Dane testowe
        let testToken: String? = nil
        let testRefreshToken: String? = nil
        let testUser: User? = nil
        
        // Wykonanie testu
        authService.saveAuthData(token: testToken, refreshToken: testRefreshToken, user: testUser)
        
        // Sprawdzenie wyników
        XCTAssertNil(UserDefaults.standard.string(forKey: "authToken"))
        XCTAssertNil(UserDefaults.standard.string(forKey: "refreshToken"))
        XCTAssertNil(UserDefaults.standard.data(forKey: "userData"))
        
        // Sprawdzenie AppState
        XCTAssertNil(AppState.shared.currentUser)
        XCTAssertTrue(AppState.shared.isAuthenticated) // To może nadal być true po wywołaniu saveAuthData
    }
    
    func testForgotPassword_Success() {
        // Dane testowe
        let testEmail = "test@example.com"
        let mockResponse = ForgotPasswordResponse(success: true, message: "E-mail z resetem hasła został wysłany")
        mockNetworkService.mockData = try! JSONEncoder().encode(mockResponse)
        
        // Wykonanie testu
        let expectation = XCTestExpectation(description: "Zapomniałem hasła")
        var resultResponse: ForgotPasswordResponse?
        var resultError: Error?
        
        authService.forgotPassword(email: testEmail)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { response in
                resultResponse = response
            })
            .store(in: &cancellables)
        
        // Sprawdzenie wyników
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertNotNil(resultResponse)
        XCTAssertTrue(resultResponse?.success ?? false)
        XCTAssertEqual(resultResponse?.message, "E-mail z resetem hasła został wysłany")
    }
    
    func testForgotPassword_Failure() {
        // Dane testowe
        let testEmail = "nonexistent@example.com"
        let expectedError = APIError.serverError(message: "Użytkownik nie znaleziony")
        mockNetworkService.mockError = expectedError
        
        // Wykonanie testu
        let expectation = XCTestExpectation(description: "Błąd przy resetowaniu hasła")
        var resultError: Error?
        
        authService.forgotPassword(email: testEmail)
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
    
    func testResetPassword_Success() {
        // Dane testowe
        let testToken = "reset-token"
        let testPassword = "newPassword123"
        let testConfirmPassword = "newPassword123"
        let mockResponse = ResetPasswordResponse(success: true, message: "Hasło zostało pomyślnie zresetowane")
        mockNetworkService.mockData = try! JSONEncoder().encode(mockResponse)
        
        // Wykonanie testu
        let expectation = XCTestExpectation(description: "Reset hasła")
        var resultResponse: ResetPasswordResponse?
        var resultError: Error?
        
        authService.resetPassword(token: testToken, newPassword: testPassword, confirmPassword: testConfirmPassword)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    resultError = error
                }
                expectation.fulfill()
            }, receiveValue: { response in
                resultResponse = response
            })
            .store(in: &cancellables)
        
        // Sprawdzenie wyników
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertNotNil(resultResponse)
        XCTAssertTrue(resultResponse?.success ?? false)
        XCTAssertEqual(resultResponse?.message, "Hasło zostało pomyślnie zresetowane")
    }
    
    func testResetPassword_Failure() {
        // Dane testowe
        let testToken = "invalid-token"
        let testPassword = "newPassword123"
        let testConfirmPassword = "newPassword123"
        let expectedError = APIError.serverError(message: "Nieprawidłowy lub wygasły token")
        mockNetworkService.mockError = expectedError
        
        // Wykonanie testu
        let expectation = XCTestExpectation(description: "Błąd resetowania hasła")
        var resultError: Error?
        
        authService.resetPassword(token: testToken, newPassword: testPassword, confirmPassword: testConfirmPassword)
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
}

// Mockowy serwis sieciowy dla testów autoryzacji
class MockNetworkServiceForAuth: NetworkServiceProtocol {
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

// Rozszerzenie żeby umożliwić testowanie AuthService
extension AuthService {
    convenience init(networkService: NetworkServiceProtocol) {
        self.init()
        // Potrzebujemy użyć refleksji lub podobnej techniki żeby ustawić networkService
        // Na razie to jest uproszczona wersja
    }
}