// LoginView.swift
/// Ekran logowania użytkownika z gradientowym tłem i animacjami
import SwiftUI

struct LoginView: View {
    
    /// Czy hasło ma być widoczne (toggle dla ikony oka)
    @State private var showPassword = false
    
    /// Czy wyświetlić ekran rejestracji
    @State private var showRegistration = false
    
    /// Czy wyświetlić ekran resetowania hasła
    @State private var showForgotPassword = false
    
    /// Globalny stan aplikacji (wstrzyknięty przez SwiftUI)
    @EnvironmentObject private var appState: AppState
    
    /// ViewModel zarządzający logiką logowania
    @StateObject private var viewModel: LoginViewModel
    
    /// Inicjalizator tworzjący ViewModel z referencją do AppState
    init() {
        _viewModel = StateObject(wrappedValue: LoginViewModel(appState: AppState.shared))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 35) {
                        // Logo i tytuł aplikacji
                        VStack(spacing: 20) {
                            // Ikona aplikacji w kołku z cieniem
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 140, height: 140)
                                
                                Image(systemName: "creditcard.and.123")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.white)
                            }
                            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            // Nazwa aplikacji i opis
                            VStack(spacing: 8) {
                                Text("DzielSię")
                                    .font(.system(size: 42, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Łatwe dzielenie kosztów")
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding(.top, 60)
                        
                        // Formularz logowania z polami email i hasło
                        VStack(spacing: 25) {
                            // Pole wprowadzania adresu email
                            VStack(alignment: .leading, spacing: 12) {
                                Text("ADRES EMAIL")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.8))
                                    .kerning(0.5)
                                
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                        .frame(width: 20)
                                    
                                    TextField("jan.kowalski@email.com", text: $viewModel.email)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .foregroundColor(.white)
                                        .tint(.white)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            
                            // Pole wprowadzania hasła z opcją pokazania/ukrycia
                            VStack(alignment: .leading, spacing: 12) {
                                Text("HASŁO")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.8))
                                    .kerning(0.5)
                                
                                HStack {
                                    // Ikona kłódki
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                        .frame(width: 20)
                                    
                                    // Pole hasła - zwykłe lub bezpieczne w zależności od showPassword
                                    if showPassword {
                                        TextField("Wprowadź hasło", text: $viewModel.password)
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                            .foregroundColor(.white)
                                            .tint(.white)
                                    } else {
                                        SecureField("Wprowadź hasło", text: $viewModel.password)
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                            .foregroundColor(.white)
                                            .tint(.white)
                                    }
                                    
                                    // Przycisk pokazania/ukrycia hasła
                                    Button(action: {
                                        showPassword.toggle()
                                    }) {
                                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            
                            // Link do resetowania hasła
                            HStack {
                                Spacer()
                                
                                Button(action: {
                                    showForgotPassword = true
                                }) {
                                    Text("Zapomniałem hasła")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .underline()
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        // Główny przycisk logowania z animacją
                        Button(action: {
                            viewModel.login()
                        }) {
                            HStack {
                                Text("Zaloguj się")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            .foregroundColor(viewModel.isFormValid ? .blue : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            )
                            .padding(.horizontal, 32)
                        }
                        .disabled(!viewModel.isFormValid || viewModel.isLoading)
                        .scaleEffect(viewModel.isFormValid ? 1.0 : 0.98)  // Animacja skali
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isFormValid)
                        
                        // Rejestracja
                        VStack(spacing: 15) {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                                .padding(.horizontal, 60)
                            
                            HStack(spacing: 8) {
                                Text("Nie masz jeszcze konta?")
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Button(action: {
                                    showRegistration = true
                                }) {
                                    Text("Dołącz do nas")
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .underline()
                                }
                            }
                            .font(.subheadline)
                        }
                        .padding(.top, 20)
                        
                        Spacer(minLength: 30)
                    }
                }
            }
                
                // Overlay z wskaźnikiem ładowania podczas logowania
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
                    title: Text("Błąd logowania"),
                    message: Text(viewModel.error ?? "Nieznany błąd"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .fullScreenCover(isPresented: $appState.isAuthenticated) {
                // Tutaj przejście do głównego widoku aplikacji
                MainAppView()
            }
            .sheet(isPresented: $showRegistration) {
                RegistrationView()
            }
            .fullScreenCover(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }

// Placeholder dla pozostałych ekranów

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
