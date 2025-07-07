//
//  RegistrationView.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 05/04/2025.
//

import SwiftUI

struct RegistrationView: View {
    @StateObject private var viewModel = RegistrationViewModel()
    @State private var showPassword = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.6), Color.teal.opacity(0.4)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Logo i tytuł
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "person.2.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.white)
                            }
                            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                            
                            VStack(spacing: 8) {
                                Text("Dołącz do nas")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Stwórz nowe konto")
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding(.top, 40)
                        
                        // Formularz rejestracji
                        VStack(spacing: 20) {
                            // Imię i Nazwisko w jednym rzędzie
                            HStack(spacing: 15) {
                                ModernTextField(label: "IMIĘ", text: $viewModel.firstName, icon: "person.fill")
                                ModernTextField(label: "NAZWISKO", text: $viewModel.lastName, icon: "person.fill")
                            }
                            
                            // Email
                            ModernTextField(label: "ADRES EMAIL", text: $viewModel.email, icon: "envelope.fill")
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            
                            // Hasło
                            ModernPasswordField(label: "HASŁO", text: $viewModel.password, showPassword: $showPassword)
                            
                            // Potwierdź hasło
                            ModernPasswordField(label: "POTWIERDŹ HASŁO", text: $viewModel.confirmPassword, showPassword: $showPassword)
                            
                            // Numer telefonu
                            ModernTextField(label: "TELEFON (OPCJONALNIE)", text: $viewModel.phoneNumber, icon: "phone.fill")
                                .keyboardType(.phonePad)
                            
                            // Akceptacja regulaminu
                            HStack(spacing: 12) {
                                Button(action: {
                                    viewModel.hasAgreedToTerms.toggle()
                                }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(viewModel.hasAgreedToTerms ? Color.white : Color.white.opacity(0.2))
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                            )
                                        
                                        if viewModel.hasAgreedToTerms {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.green)
                                                .font(.system(size: 14, weight: .bold))
                                        }
                                    }
                                }
                                
                                Text("Akceptuję regulamin i politykę prywatności")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Spacer()
                            }
                            .padding(.top, 10)
                            
                            // Przycisk rejestracji
                            Button(action: {
                                viewModel.register()
                            }) {
                                HStack {
                                    Text("Załóż konto")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Image(systemName: "person.badge.plus.fill")
                                }
                                .foregroundColor(viewModel.isFormValid ? .green : .gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                )
                            }
                            .disabled(!viewModel.isFormValid || viewModel.isLoading)
                            .scaleEffect(viewModel.isFormValid ? 1.0 : 0.98)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.isFormValid)
                        }
                        .padding(.horizontal, 25)
                        
                        Spacer(minLength: 30)
                    }
                }
            }
                
                // Wskaźnik ładowania
                if viewModel.isLoading {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .navigationBarHidden(true)
            .alert(isPresented: Binding<Bool>(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Alert(
                    title: Text("Błąd rejestracji"),
                    message: Text(viewModel.error ?? "Wystąpił nieznany błąd"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onChange(of: viewModel.isRegistered) { registered in
                if registered {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }


// Dodatkowe widoki pomocnicze
struct ModernTextField: View {
    let label: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.8))
                .kerning(0.5)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 20)
                
                TextField(label.lowercased(), text: $text)
                    .foregroundColor(.white)
                    .tint(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

struct ModernPasswordField: View {
    let label: String
    @Binding var text: String
    @Binding var showPassword: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.8))
                .kerning(0.5)
            
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 20)
                
                if showPassword {
                    TextField(label.lowercased(), text: $text)
                        .autocapitalization(.none)
                        .foregroundColor(.white)
                        .tint(.white)
                } else {
                    SecureField(label.lowercased(), text: $text)
                        .autocapitalization(.none)
                        .foregroundColor(.white)
                        .tint(.white)
                }
                
                Button(action: {
                    showPassword.toggle()
                }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView()
    }
}
