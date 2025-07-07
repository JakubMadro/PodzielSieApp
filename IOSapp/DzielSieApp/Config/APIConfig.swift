//
//  APIConfig.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 05/04/2025.
//

import Foundation

/// Enum definiujący różne środowiska API
/// Pozwala na łatwe przełączanie między serwerami testowymi i produkcyjnymi
enum APIEnvironment {
    /// Środowisko deweloperskie (serwer testowy)
    case development
    
    /// Środowisko produkcyjne (serwer docelowy)
    case production
    
    /// Środowisko lokalne (serwer deweloperski na localhost)
    case localhost
    
    /// Zwraca bazowy URL dla danego środowiska
    var baseURL: String {
        switch self {
        case .development:
            // Serwer testowy na Azure
            return "https://dzielsieapp-aceua3ewcva9dkhw.canadacentral-01.azurewebsites.net/api"
        case .production:
            // Serwer produkcyjny - do konfiguracji
            return "prod.api"
        case .localhost:
            // Lokalny serwer deweloperski
            return "http://localhost:5545/api" // Zastąp X swoim lokalnym adresem IP
        }
    }
}

/// Struktura konfiguracyjna API
/// Automatycznie wybiera odpowiednie środowisko w zależności od platformy
struct APIConfig {
    /// Bieżące środowisko API wybrane automatycznie
    /// - Symulator: localhost
    /// - Urządzenie iOS: development
    /// - Inne platformy: production
    static var current: APIEnvironment {
        #if targetEnvironment(simulator)
            return .localhost  // Symulator używa lokalnego serwera
        #elseif os(iOS)
            return .development  // Urządzenie iOS używa serwera deweloperskiego
        #else
            return .production  // Pozostałe platformy używają serwera produkcyjnego
        #endif
    }
}
