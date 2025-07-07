//
//  NetworkService.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 05/04/2025.
//

import Foundation
import Combine

protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) -> AnyPublisher<T, Error>
}

final class NetworkService: NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) -> AnyPublisher<T, Error> {
        // Tworzymy podstawowy URL
        var urlComponents = URLComponents(string: APIConfig.current.baseURL + endpoint.path)
        
        // Dodajemy parametry zapytania, jeśli istnieją
        if let queryParams = endpoint.queryParameters, !queryParams.isEmpty {
            urlComponents?.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = urlComponents?.url else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Print the request URL for debugging
        print("Sending \(endpoint.method.rawValue) request to \(url.absoluteString)")
        
        // Dodajemy token autoryzacyjny jeśli endpoint tego wymaga
        if endpoint.requiresAuthentication {
            if let token = UserDefaults.standard.string(forKey: "authToken") {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                print("Adding auth token to request")
            } else {
                return Fail(error: APIError.unauthorized).eraseToAnyPublisher()
            }
        }
        
        if let body = endpoint.body {
            do {
                // Serializujemy słownik do JSON
                let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
                request.httpBody = jsonData
                
                // Wydrukuj body żądania w formacie czytelnym dla człowieka
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("Request body: \(jsonString)")
                }
            } catch {
                print("Error serializing request body: \(error)")
                return Fail(error: APIError.networkError(error)).eraseToAnyPublisher()
            }
        }
        
        // Print the headers for debugging
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        // Skonfiguruj JSONDecoder dla dat
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { error in
                print("Network error: \(error.localizedDescription)")
                return APIError.networkError(error)
            }
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response")
                    throw APIError.invalidResponse
                }
                
                // Wydrukuj status kodu i treść odpowiedzi
                let responseString = String(data: data, encoding: .utf8) ?? "Brak treści"
                print("HTTP Status Code: \(httpResponse.statusCode)")
                print("Response: \(responseString)")
                
                guard 200..<300 ~= httpResponse.statusCode else {
                    if httpResponse.statusCode == 401 {
                        throw APIError.unauthorized
                    }
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw APIError.serverError(message: "HTTP \(httpResponse.statusCode): \(errorMessage)")
                }
                return data
            }
            .decode(type: T.self, decoder: decoder)
            .mapError { error in
                if error is DecodingError {
                    print("Decoding error: \(error)")
                    return APIError.decodingError
                }
                return error
            }
            .eraseToAnyPublisher()
    }
}
