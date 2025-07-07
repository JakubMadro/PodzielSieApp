//
//  MainAppView.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 05/04/2025.
//

import SwiftUI

/// Główny ekran aplikacji z nawigacją tabelaryczną
/// Zawiera 5 zakładek: Pulpit, Grupy, Wydatki, Rozliczenia, Ustawienia
struct MainAppView: View {
    /// Globalny stan aplikacji
    @EnvironmentObject var appState: AppState
    
    /// Indeks aktualnie wybranej zakładki
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Zakładka 1: Pulpit - przegląd aktywności i szybkie akcje
            DashboardView()
                .tabItem {
                    Label("Pulpit", systemImage: "house.fill")
                }
                .tag(0)
            
            // Zakładka 2: Grupy - zarządzanie grupami wydatków
            GroupsView()
                .tabItem {
                    Label("Grupy", systemImage: "person.3.fill")
                }
                .tag(1)
            
            // Zakładka 3: Wydatki - przeglądanie i dodawanie wydatków
            ExpensesView()
                .tabItem {
                    Label("Wydatki", systemImage: "creditcard.fill")
                }
                .tag(2)
            
            // Zakładka 4: Rozliczenia - zarządzanie rozliczeniami między użytkownikami
            SettlementsView()
                .tabItem {
                    Label("Rozliczenia", systemImage: "arrow.left.arrow.right")
                }
                .tag(3)
            
            // Zakładka 5: Ustawienia - konfiguracja aplikacji i profil użytkownika
            SettingsView()
                .tabItem {
                    Label("Ustawienia", systemImage: "gear")
                }
                .tag(4)
        }
        .accentColor(.blue)  // Kolor aktywnej zakładki
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    /// Konfiguruje wygląd paska zakładek
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().standardAppearance = appearance
        
        // Dla iOS 15+ ustawia także wygląd przy przewijaniu
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - SwiftUI Previews
struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppView()
            .environmentObject(AppState.shared)
    }
}

// MARK: - Extensions
extension User {
    /// Zwraca inicjały użytkownika (pierwsza litera imienia i nazwiska)
    var initials: String {
        let firstNameInitial = firstName.prefix(1).uppercased()
        let lastNameInitial = lastName.prefix(1).uppercased()
        return "\(firstNameInitial)\(lastNameInitial)"
    }
}
