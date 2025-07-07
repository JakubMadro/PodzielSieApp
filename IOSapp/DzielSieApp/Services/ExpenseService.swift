//
//  ExpenseServiceProtocol.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 06/04/2025.
//


import Foundation
import Combine

protocol ExpenseServiceProtocol {
    func createExpense(_ expenseData: ExpenseCreateData) -> AnyPublisher<Expense, Error>
    func getGroupExpenses(groupId: String, page: Int, limit: Int) -> AnyPublisher<ExpensesResponse, Error>
    func getExpenseDetails(expenseId: String) -> AnyPublisher<Expense, Error>
    func updateExpense(expenseId: String, updateData: [String: Any]) -> AnyPublisher<Expense, Error>
    func deleteExpense(expenseId: String) -> AnyPublisher<Bool, Error>
    func addComment(expenseId: String, text: String) -> AnyPublisher<ExpenseComment, Error>
}

class ExpenseService: ExpenseServiceProtocol {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    func createExpense(_ expenseData: ExpenseCreateData) -> AnyPublisher<Expense, Error> {
        // Tworzymy endpoint for createExpense
        return createExpenseRequest(expenseData: expenseData)
            .map { (response: ExpenseResponse) -> Expense in
                return response.expense
            }
            .eraseToAnyPublisher()
    }
    
    func getGroupExpenses(groupId: String, page: Int = 1, limit: Int = 20) -> AnyPublisher<ExpensesResponse, Error> {
        // Tworzymy endpoint for getGroupExpenses
        return getGroupExpensesRequest(groupId: groupId, page: page, limit: limit)
            .eraseToAnyPublisher()
    }
    
    func getExpenseDetails(expenseId: String) -> AnyPublisher<Expense, Error> {
        // Tworzymy endpoint for getExpenseDetails
        return getExpenseDetailsRequest(expenseId: expenseId)
            .map { (response: ExpenseResponse) -> Expense in
                return response.expense
            }
            .eraseToAnyPublisher()
    }
    
    func updateExpense(expenseId: String, updateData: [String: Any]) -> AnyPublisher<Expense, Error> {
        // Tworzymy endpoint for updateExpense
        return updateExpenseRequest(expenseId: expenseId, updateData: updateData)
            .map { (response: ExpenseResponse) -> Expense in
                return response.expense
            }
            .eraseToAnyPublisher()
    }
    
    func deleteExpense(expenseId: String) -> AnyPublisher<Bool, Error> {
        // Tworzymy endpoint for deleteExpense
        return deleteExpenseRequest(expenseId: expenseId)
            .map { (response: DeleteResponse) -> Bool in
                return response.success
            }
            .eraseToAnyPublisher()
    }
    
    func addComment(expenseId: String, text: String) -> AnyPublisher<ExpenseComment, Error> {
        // Tworzymy endpoint for addComment
        return addCommentRequest(expenseId: expenseId, text: text)
            .map { (response: CommentResponse) -> ExpenseComment in
                return response.comment
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private methods for network requests
    
    private func createExpenseRequest(expenseData: ExpenseCreateData) -> AnyPublisher<ExpenseResponse, Error> {
        let url = URL(string: "\(APIConfig.current.baseURL)/expenses")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Dodajemy token autoryzacyjny
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Konwertujemy dane ekspensa do JSON
        do {
            let encoder = JSONEncoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            encoder.dateEncodingStrategy = .formatted(dateFormatter)
            
            request.httpBody = try encoder.encode(expenseData)
            print("Request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "invalid JSON")")
        } catch {
            return Fail(error: APIError.networkError(error)).eraseToAnyPublisher()
        }
        
        // Wykonujemy zapytanie
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                print("HTTP Status: \(httpResponse.statusCode)")
                print("Response: \(String(data: data, encoding: .utf8) ?? "invalid data")")
                
                guard 200..<300 ~= httpResponse.statusCode else {
                    if httpResponse.statusCode == 401 {
                        throw APIError.unauthorized
                    }
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw APIError.serverError(message: "HTTP \(httpResponse.statusCode): \(errorMessage)")
                }
                
                return data
            }
            .decode(type: ExpenseResponse.self, decoder: createDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else if error is DecodingError {
                    print("Decoding error: \(error)")
                    return APIError.decodingError
                }
                return APIError.networkError(error)
            }
            .eraseToAnyPublisher()
    }
    
    private func getGroupExpensesRequest(groupId: String, page: Int, limit: Int) -> AnyPublisher<ExpensesResponse, Error> {
        var components = URLComponents(string: "\(APIConfig.current.baseURL)/groups/\(groupId)/expenses")!
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        
        // Dodajemy token autoryzacyjny
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                guard 200..<300 ~= httpResponse.statusCode else {
                    if httpResponse.statusCode == 401 {
                        throw APIError.unauthorized
                    }
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw APIError.serverError(message: "HTTP \(httpResponse.statusCode): \(errorMessage)")
                }
                
                return data
            }
            .decode(type: ExpensesResponse.self, decoder: createDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else if error is DecodingError {
                    print("Decoding error: \(error)")
                    return APIError.decodingError
                }
                return APIError.networkError(error)
            }
            .eraseToAnyPublisher()
    }
    
    private func getExpenseDetailsRequest(expenseId: String) -> AnyPublisher<ExpenseResponse, Error> {
        let url = URL(string: "\(APIConfig.current.baseURL)/expenses/\(expenseId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Dodajemy token autoryzacyjny
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                guard 200..<300 ~= httpResponse.statusCode else {
                    if httpResponse.statusCode == 401 {
                        throw APIError.unauthorized
                    }
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw APIError.serverError(message: "HTTP \(httpResponse.statusCode): \(errorMessage)")
                }
                
                return data
            }
            .decode(type: ExpenseResponse.self, decoder: createDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else if error is DecodingError {
                    print("Decoding error: \(error)")
                    return APIError.decodingError
                }
                return APIError.networkError(error)
            }
            .eraseToAnyPublisher()
    }
    
    private func updateExpenseRequest(expenseId: String, updateData: [String: Any]) -> AnyPublisher<ExpenseResponse, Error> {
        let url = URL(string: "\(APIConfig.current.baseURL)/expenses/\(expenseId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Dodajemy token autoryzacyjny
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Konwertujemy dane do JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: updateData)
        } catch {
            return Fail(error: APIError.networkError(error)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                guard 200..<300 ~= httpResponse.statusCode else {
                    if httpResponse.statusCode == 401 {
                        throw APIError.unauthorized
                    }
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw APIError.serverError(message: "HTTP \(httpResponse.statusCode): \(errorMessage)")
                }
                
                return data
            }
            .decode(type: ExpenseResponse.self, decoder: createDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else if error is DecodingError {
                    print("Decoding error: \(error)")
                    return APIError.decodingError
                }
                return APIError.networkError(error)
            }
            .eraseToAnyPublisher()
    }
    
    private func deleteExpenseRequest(expenseId: String) -> AnyPublisher<DeleteResponse, Error> {
        let url = URL(string: "\(APIConfig.current.baseURL)/expenses/\(expenseId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        // Dodajemy token autoryzacyjny
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                guard 200..<300 ~= httpResponse.statusCode else {
                    if httpResponse.statusCode == 401 {
                        throw APIError.unauthorized
                    }
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw APIError.serverError(message: "HTTP \(httpResponse.statusCode): \(errorMessage)")
                }
                
                return data
            }
            .decode(type: DeleteResponse.self, decoder: createDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else if error is DecodingError {
                    print("Decoding error: \(error)")
                    return APIError.decodingError
                }
                return APIError.networkError(error)
            }
            .eraseToAnyPublisher()
    }
    
    private func addCommentRequest(expenseId: String, text: String) -> AnyPublisher<CommentResponse, Error> {
        let url = URL(string: "\(APIConfig.current.baseURL)/expenses/\(expenseId)/comments")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Dodajemy token autoryzacyjny
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Konwertujemy dane komentarza do JSON
        do {
            let commentData = ["text": text]
            request.httpBody = try JSONSerialization.data(withJSONObject: commentData)
        } catch {
            return Fail(error: APIError.networkError(error)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                guard 200..<300 ~= httpResponse.statusCode else {
                    if httpResponse.statusCode == 401 {
                        throw APIError.unauthorized
                    }
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw APIError.serverError(message: "HTTP \(httpResponse.statusCode): \(errorMessage)")
                }
                
                return data
            }
            .decode(type: CommentResponse.self, decoder: createDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else if error is DecodingError {
                    print("Decoding error: \(error)")
                    return APIError.decodingError
                }
                return APIError.networkError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Helper methods
    
    private func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }
}

// MARK: - Response structures for network requests

struct DeleteResponse: Codable {
    let success: Bool
    let message: String
}

struct CommentResponse: Codable {
    let success: Bool
    let message: String
    let comment: ExpenseComment
}
