//
//  APIConfig.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 05/04/2025.
//

import Foundation

enum APIEnvironment {
    case development
    case production
    case localhost
    
    var baseURL: String {
        switch self {
        case .development:
            return "https://dzielsieapp-aceua3ewcva9dkhw.canadacentral-01.azurewebsites.net/api"
        case .production:
            return "prod.api"
        case .localhost:
            return "http://localhost:5545/api" // Zastąp X swoim lokalnym adresem IP
        }
    }
}

struct APIConfig {
    // Możesz dynamicznie ustawiać środowisko
    static var current: APIEnvironment {
        #if targetEnvironment(simulator)
            return .localhost
        #elseif os(iOS)
            return .development
        #else
            return .production
        #endif
    }
}
