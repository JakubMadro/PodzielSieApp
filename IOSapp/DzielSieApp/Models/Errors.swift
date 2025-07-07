//
//  Errors.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 05/04/2025.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case serverError(message: String)
    case decodingError
    case networkError(Error)
    case unauthorized
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Nieprawidłowy adres URL"
        case .invalidResponse:
            return "Nieprawidłowa odpowiedź serwera"
        case .serverError(let message):
            return message
        case .decodingError:
            return "Błąd przetwarzania danych"
        case .networkError(let error):
            return "Błąd sieci: \(error.localizedDescription)"
        case .unauthorized:
            return "Brak autoryzacji. Zaloguj się ponownie."
        }
    }
}
