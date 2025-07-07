//
//  ContentView.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 05/04/2025.
//

import SwiftUI

/// Podstawowy widok ContentView - obecnie nieaktywny w aplikacji
/// Ten widok był utworzony automatycznie przez Xcode, ale nie jest używany
/// Głównym punktem wejścia jest DzielSieAppApp.swift -> LoginView/MainAppView
struct ContentView: View {
    var body: some View {
        VStack {
            // Ikona globusa
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            
            // Tekst powitalny
            Text("Hello, world!")
        }
        .padding()
    }
}

// MARK: - SwiftUI Previews
#Preview {
    ContentView()
}
