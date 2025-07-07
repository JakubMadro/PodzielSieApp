//
//  EmptyGroupsView.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//

import SwiftUI

struct EmptyGroupsView: View {
    let onAddGroup: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.7))
            
            Text("Nie masz jeszcze żadnych grup")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Utwórz swoją pierwszą grupę, aby dzielić wydatki z przyjaciółmi lub rodziną.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: onAddGroup) {
                Label("Utwórz pierwszą grupę", systemImage: "plus")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
        }
    }
}
