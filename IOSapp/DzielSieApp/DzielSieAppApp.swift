//
//  DzielSieAppApp.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 05/04/2025.
//

import SwiftUI

@main
struct DzielSieAppApp: App {
    @StateObject private var appState = AppState.shared
    
    init() {
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            SwiftUI.Group {
                if appState.isAuthenticated {
                    MainAppView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(appState)
        }
    }
    
    private func setupAppearance() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = .systemBackground
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}
