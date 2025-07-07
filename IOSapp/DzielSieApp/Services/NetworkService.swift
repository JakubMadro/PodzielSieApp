//
//  NetworkService.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 05/04/2025.
//

import Foundation
import Combine

/// Protokół definiujący interfejs serwisu sieciowego
/// Generic T pozwala na zwracanie różnych typów odpowiedzi
protocol NetworkServiceProtocol {
    /// Wykonuje żądanie HTTP dla podanego endpointu
    /// - Parameter endpoint: Konfiguracja endpointu API
    /// - Returns: Publisher z odpowiedzią lub błędem
    func request<T: Decodable>(_ endpoint: APIEndpoint) -> AnyPublisher<T, Error>
}

/// Serwis sieciowy odpowiedzialny za komunikację z API
/// final - nie może być dziedziczona
final class NetworkService: NetworkServiceProtocol {
    /// Wykonuje żądanie HTTP i zwraca zdekodowane dane
    /// - Parameter endpoint: Konfiguracja endpointu (URL, metoda, parametry)
    /// - Returns: Publisher z odpowiedzią JSON zdekodowaną do typu T
    func request<T: Decodable>(_ endpoint: APIEndpoint) -> AnyPublisher<T, Error> {
        // Buduj URL z base URL i ścieżką endpointu
        var urlComponents = URLComponents(string: APIConfig.current.baseURL + endpoint.path)
        
        // Dodaj parametry zapytania do URL jeśli istnieją (np. ?page=1&limit=10)
        if let queryParams = endpoint.queryParameters, !queryParams.isEmpty {
            urlComponents?.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        // Sprawdź czy URL został poprawnie utworzony
        guard let url = urlComponents?.url else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        // Utwórz żądanie HTTP
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Debug: wydrukuj URL żądania
        print("Sending \(endpoint.method.rawValue) request to \(url.absoluteString)")
        
        // Dodaj token autoryzacyjny do nagłówka jeśli endpoint wymaga autoryzacji
        if endpoint.requiresAuthentication {
            if let token = UserDefaults.standard.string(forKey: "authToken") {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                print("Adding auth token to request")
            } else {
                // Brak tokenu - zwróć błąd nieautoryzowanego dostępu
                return Fail(error: APIError.unauthorized).eraseToAnyPublisher()
            }
        }
        
        // Dodaj body do żądania jeśli istnieje (dla POST, PUT, PATCH)
        if let body = endpoint.body {
            do {
                // Serializuj słownik do formatu JSON
                let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
                request.httpBody = jsonData
                
                // Debug: wydrukuj zawartość body w czytelnym formacie
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("Request body: \(jsonString)")
                }
            } catch {
                print("Error serializing request body: \(error)")
                return Fail(error: APIError.networkError(error)).eraseToAnyPublisher()
            }
        }
        
        // Debug: wydrukuj wszystkie nagłówki żądania
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        // Skonfiguruj dekoder JSON do obsługi dat w formacie ISO 8601
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"  // Format dat z API
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        // Wykonaj żądanie HTTP i przetwórz odpowiedź
        return URLSession.shared.dataTaskPublisher(for: request)
            // Obsłuż błędy sieciowe (brak internetu, timeout, itp.)
            .mapError { error in
                print("Network error: \(error.localizedDescription)")
                return APIError.networkError(error)
            }
            // Sprawdz status odpowiedzi i wyciągnij dane
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response")
                    throw APIError.invalidResponse
                }
                
                // Debug: wydrukuj status i zawartość odpowiedzi
                let responseString = String(data: data, encoding: .utf8) ?? "Brak treści"
                print("HTTP Status Code: \(httpResponse.statusCode)")
                print("Response: \(responseString)")
                
                // Sprawdź czy status jest w zakresie sukcesów (200-299)
                guard 200..<300 ~= httpResponse.statusCode else {
                    if httpResponse.statusCode == 401 {
                        throw APIError.unauthorized  // Nieautoryzowany dostęp
                    }
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw APIError.serverError(message: "HTTP \(httpResponse.statusCode): \(errorMessage)")
                }
                return data
            }
            // Zdekoduj dane JSON do typu T
            .decode(type: T.self, decoder: decoder)
            // Obsłuż błędy dekodowania JSON
            .mapError { error in
                if error is DecodingError {
                    print("Decoding error: \(error)")
                    return APIError.decodingError
                }
                return error
            }
            .eraseToAnyPublisher()  // Wymaż typ Publisher dla czytelności
    }
}
