//
//  AppState.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 05/04/2025.
//

import Foundation
import Combine

/// Globalny stan aplikacji zarządzający autoryzacją i danymi użytkownika
/// ObservableObject pozwala na automatyczne odświeżanie UI przy zmianach
class AppState: ObservableObject {
    /// Singleton - jedna instancja na całą aplikację
    static let shared = AppState()
    
    /// Czy użytkownik jest zalogowany (obserwowalne przez UI)
    @Published var isAuthenticated: Bool
    
    /// Dane aktualnie zalogowanego użytkownika (obserwowalne przez UI)
    @Published var currentUser: User?
    
    /// Inicjalizator - sprawdza czy użytkownik jest już zalogowany
    init() {
        // Sprawdź czy istnieje token autoryzacji w UserDefaults
        self.isAuthenticated = UserDefaults.standard.string(forKey: "authToken") != nil
        // Załaduj dane użytkownika z pamięci lokalnej
        self.loadUserData()
    }
    
    /// Ładuje dane użytkownika z UserDefaults przy starcie aplikacji
    private func loadUserData() {
        // Spróbuj pobrać i zdekodować dane użytkownika z pamięci lokalnej
        if let data = UserDefaults.standard.data(forKey: "userData"),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            self.currentUser = user
        }
    }
    
    /// Wylogowuje użytkownika - czyści wszystkie dane z pamięci lokalnej
    func logout() {
        // Usuń token autoryzacji
        UserDefaults.standard.removeObject(forKey: "authToken")
        // Usuń token odświeżania
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        // Usuń dane użytkownika
        UserDefaults.standard.removeObject(forKey: "userData")
        
        // Zaktualizuj stan aplikacji
        isAuthenticated = false
        currentUser = nil
    }
}
