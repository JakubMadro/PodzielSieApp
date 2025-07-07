//
//  DashboardService.swift
//  DzielSieApp
//
//  Created by Claude on 06/04/2025.
//

import Foundation
import Combine

protocol DashboardServiceProtocol {
    func fetchRecentActivities(limit: Int) -> AnyPublisher<[Activity], Error>
}

class DashboardService: DashboardServiceProtocol {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    func fetchRecentActivities(limit: Int = 5) -> AnyPublisher<[Activity], Error> {
        let urlString = "\(APIConfig.current.baseURL)/users/activities?limit=\(limit)"
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
            .tryMap { data -> [Activity] in
                // Dekodujemy JSON do tymczasowej struktury
                let decoder = JSONDecoder()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                
                let response = try decoder.decode(ActivitiesResponse.self, from: data)
                
                // Konwertujemy DTO na obiekty Activity
                return response.activities.map { dto in
                    Activity(
                        id: dto.id,
                        type: self.activityTypeFrom(string: dto.type),
                        title: dto.title,
                        subtitle: dto.subtitle,
                        amount: dto.amount,
                        currency: dto.currency,
                        date: dto.date,
                        iconName: dto.iconName,
                        groupId: dto.groupId,
                        expenseId: dto.expenseId
                    )
                }
            }
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
    
    // Konwersja typu aktywności z stringa do enuma
    private func activityTypeFrom(string: String) -> ActivityType {
        switch string {
        case "newExpense": return .newExpense
        case "addedToGroup": return .addedToGroup
        case "settledExpense": return .settledExpense
        case "groupCreated": return .groupCreated
        case "memberAdded": return .memberAdded
        default: return .newExpense
        }
    }
}

// Struktury do dekodowania odpowiedzi JSON
private struct ActivitiesResponse: Decodable {
    let success: Bool
    let activities: [ActivityDTO]
}

private struct ActivityDTO: Decodable {
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
}
