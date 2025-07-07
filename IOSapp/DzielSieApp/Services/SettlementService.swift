//
//  SettlementService.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//


import Foundation
import Combine

protocol SettlementServiceProtocol {
    func getGroupBalances(groupId: String) -> AnyPublisher<GroupBalancesResponse, Error>
    func getPendingSettlements() -> AnyPublisher<SettlementsResponse, Error>
    func getCompletedSettlements() -> AnyPublisher<SettlementsResponse, Error>
    func getAllSettlements() -> AnyPublisher<SettlementsResponse, Error>
    func getSettlementDetails(settlementId: String) -> AnyPublisher<Settlement, Error>
    func settleDebt(settlementId: String, paymentMethod: PaymentMethod, paymentReference: String?) -> AnyPublisher<Settlement, Error>
    func refreshGroupBalances(groupId: String) -> AnyPublisher<GroupBalancesResponse, Error>
}

class SettlementService: SettlementServiceProtocol {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    func getGroupBalances(groupId: String) -> AnyPublisher<GroupBalancesResponse, Error> {
        let urlString = "\(APIConfig.current.baseURL)/groups/\(groupId)/balances"
        guard let url = URL(string: urlString) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
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
            .decode(type: GroupBalancesResponse.self, decoder: createDecoder())
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
    
    func getPendingSettlements() -> AnyPublisher<SettlementsResponse, Error> {
        return networkService.request(.getPendingSettlements)
    }
    
    func getCompletedSettlements() -> AnyPublisher<SettlementsResponse, Error> {
        return networkService.request(.getCompletedSettlements)
    }
    
    func getAllSettlements() -> AnyPublisher<SettlementsResponse, Error> {
        return networkService.request(.getAllSettlements)
    }
    
    func getSettlementDetails(settlementId: String) -> AnyPublisher<Settlement, Error> {
        let urlString = "\(APIConfig.current.baseURL)/settlements/\(settlementId)"
        guard let url = URL(string: urlString) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
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
            .decode(type: SettlementResponse.self, decoder: createDecoder())
            .map { $0.settlement }
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
    
    func settleDebt(settlementId: String, paymentMethod: PaymentMethod, paymentReference: String?) -> AnyPublisher<Settlement, Error> {
        let urlString = "\(APIConfig.current.baseURL)/settlements/\(settlementId)/settle"
        guard let url = URL(string: urlString) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Przygotowanie danych do wysłania
        var requestBody: [String: Any] = ["paymentMethod": paymentMethod.rawValue]
        if let reference = paymentReference {
            requestBody["paymentReference"] = reference
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
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
            .decode(type: SettlementResponse.self, decoder: createDecoder())
            .map { $0.settlement }
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
    
    func refreshGroupBalances(groupId: String) -> AnyPublisher<GroupBalancesResponse, Error> {
        let urlString = "\(APIConfig.current.baseURL)/groups/\(groupId)/balances/refresh"
        guard let url = URL(string: urlString) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
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
            .decode(type: GroupBalancesResponse.self, decoder: createDecoder())
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
    
    // Helper
    private func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }
}
