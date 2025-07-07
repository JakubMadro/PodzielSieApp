//
//  SettingsView.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 05/04/2025.
//

import SwiftUI


struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: logout) {
                        HStack {
                            Image(systemName: "arrow.backward.circle.fill")
                                .foregroundColor(.red)
                            Text("Wyloguj się")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Ustawienia")
        }
    }
    
    private func logout() {
        appState.logout()
    }
}
