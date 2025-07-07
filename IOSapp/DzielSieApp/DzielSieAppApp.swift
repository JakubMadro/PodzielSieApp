//
//  DzielSieAppApp.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 05/04/2025.
//

import SwiftUI

/// Główna struktura aplikacji - punkt wejściowy dla całej aplikacji
/// Odpowiada za konfiguracje wyglądu i zarządzanie stanem autoryzacji
@main
struct DzielSieAppApp: App {
    /// Globalny stan aplikacji jako StateObject
    @StateObject private var appState = AppState.shared
    
    /// Inicjalizator aplikacji - konfiguruje wygląd
    init() {
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            SwiftUI.Group {
                // Warunkowe wyświetlanie ekranów w zależności od stanu autoryzacji
                if appState.isAuthenticated {
                    // Użytkownik zalogowany - pokaż główny interfejs
                    MainAppView()
                } else {
                    // Użytkownik niezalogowany - pokaż ekran logowania
                    LoginView()
                }
            }
            // Wstrzyknij stan aplikacji do całego drzewa widoków
            .environmentObject(appState)
        }
    }
    
    /// Konfiguruje globalny wygląd elementów UI w całej aplikacji
    private func setupAppearance() {
        // Konfiguracja paska nawigacji
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = .systemBackground
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        
        // Zastosuj wygląd do wszystkich paseków nawigacji
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // Konfiguracja paska zakładek
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .systemBackground
        
        // Zastosuj wygląd do wszystkich paseków zakładek
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}
