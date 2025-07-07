//
//  MainAppView.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 05/04/2025.
//

import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Ekran Pulpitu
            DashboardView()
                .tabItem {
                    Label("Pulpit", systemImage: "house.fill")
                }
                .tag(0)
            
            // Ekran Grup
            GroupsView()
                .tabItem {
                    Label("Grupy", systemImage: "person.3.fill")
                }
                .tag(1)
            
            // Ekran Wydatków
            ExpensesView()
                .tabItem {
                    Label("Wydatki", systemImage: "creditcard.fill")
                }
                .tag(2)
            
            // Ekran Rozliczeń
            SettlementsView()
                .tabItem {
                    Label("Rozliczenia", systemImage: "arrow.left.arrow.right")
                }
                .tag(3)
            
            // Ekran Ustawień
            SettingsView()
                .tabItem {
                    Label("Ustawienia", systemImage: "gear")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Podglądy
struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppView()
            .environmentObject(AppState.shared)
    }
}

// MARK: - Extensions
extension User {
    var initials: String {
        let firstNameInitial = firstName.prefix(1).uppercased()
        let lastNameInitial = lastName.prefix(1).uppercased()
        return "\(firstNameInitial)\(lastNameInitial)"
    }
}
