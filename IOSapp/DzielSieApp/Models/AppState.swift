//
//  AppState.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 05/04/2025.
//

import Foundation
import Combine

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var isAuthenticated: Bool
    @Published var currentUser: User?
    
    init() {
        self.isAuthenticated = UserDefaults.standard.string(forKey: "authToken") != nil
        self.loadUserData()
    }
    
    private func loadUserData() {
        if let data = UserDefaults.standard.data(forKey: "userData"),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            self.currentUser = user
        }
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        UserDefaults.standard.removeObject(forKey: "userData")
        isAuthenticated = false
        currentUser = nil
    }
}
