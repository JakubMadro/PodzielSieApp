//
//  ResetPasswordView.swift
//  DzielSieApp
//
//  Created by Claude on 06/07/2025.
//

import SwiftUI
import Combine

struct ResetPasswordView: View {
    let email: String
    @StateObject private var viewModel = ResetPasswordViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.pink.opacity(0.4)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 35) {
                        // Header
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "lock.rotation")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.white)
                            }
                            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                            
                            VStack(spacing: 8) {
                                Text("Resetuj hasło")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Wprowadź 6-cyfrowy kod z emaila i nowe hasło")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Text("Email: \(email)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.top, 60)
                        
                        // Form
                        VStack(spacing: 25) {
                            // Token input
                            VStack(alignment: .leading, spacing: 12) {
                                Text("KOD RESETOWANIA")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.8))
                                    .kerning(0.5)
                                
                                HStack {
                                    Image(systemName: "key.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                        .frame(width: 20)
                                    
                                    TextField("123456", text: $viewModel.token)
                                        .keyboardType(.numberPad)
                                        .foregroundColor(.white)
                                        .tint(.white)
                                        .onReceive(Just(viewModel.token)) { _ in
                                            // Limit to 6 digits
                                            if viewModel.token.count > 6 {
                                                viewModel.token = String(viewModel.token.prefix(6))
                                            }
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
                            
                            // New password
                            VStack(alignment: .leading, spacing: 12) {
                                Text("NOWE HASŁO")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.8))
                                    .kerning(0.5)
                                
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                        .frame(width: 20)
                                    
                                    if showPassword {
                                        TextField("Nowe hasło", text: $viewModel.newPassword)
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                            .foregroundColor(.white)
                                            .tint(.white)
                                    } else {
                                        SecureField("Nowe hasło", text: $viewModel.newPassword)
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
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
                            
                            // Confirm password
                            VStack(alignment: .leading, spacing: 12) {
                                Text("POTWIERDŹ HASŁO")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.8))
                                    .kerning(0.5)
                                
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                        .frame(width: 20)
                                    
                                    if showConfirmPassword {
                                        TextField("Potwierdź hasło", text: $viewModel.confirmPassword)
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                            .foregroundColor(.white)
                                            .tint(.white)
                                    } else {
                                        SecureField("Potwierdź hasło", text: $viewModel.confirmPassword)
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                            .foregroundColor(.white)
                                            .tint(.white)
                                    }
                                    
                                    Button(action: {
                                        showConfirmPassword.toggle()
                                    }) {
                                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
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
                            
                            // Reset button
                            Button(action: {
                                viewModel.resetPassword()
                            }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Zmień hasło")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                }
                                .foregroundColor(viewModel.isFormValid ? .purple : .gray)
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
                        .padding(.horizontal, 32)
                        
                        // Success message
                        if viewModel.isPasswordReset {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                
                                Text("Hasło zostało zmienione!")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Text("Możesz teraz zalogować się używając nowego hasła.")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Button(action: {
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Text("Wróć do logowania")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.purple)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white)
                                        )
                                }
                                .padding(.top, 8)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 32)
                        }
                        
                        Spacer(minLength: 30)
                    }
                }
            }
            .navigationBarItems(leading: Button("Anuluj") {
                presentationMode.wrappedValue.dismiss()
            }.foregroundColor(.white))
            .navigationBarTitle("", displayMode: .inline)
            .alert(isPresented: Binding<Bool>(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Alert(
                    title: Text("Błąd"),
                    message: Text(viewModel.error ?? "Wystąpił nieznany błąd"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

class ResetPasswordViewModel: ObservableObject {
    @Published var token = ""
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var error: String?
    @Published var isPasswordReset = false
    
    private let authService: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    var isFormValid: Bool {
        return token.count == 6 &&
               !newPassword.isEmpty &&
               newPassword.count >= 6 &&
               newPassword == confirmPassword
    }
    
    init(authService: AuthServiceProtocol = AuthService.shared) {
        self.authService = authService
    }
    
    func resetPassword() {
        guard isFormValid else { return }
        
        isLoading = true
        error = nil
        
        authService.resetPassword(token: token, newPassword: newPassword, confirmPassword: confirmPassword)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] response in
                if response.success {
                    self?.isPasswordReset = true
                } else {
                    self?.error = response.message
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            self.error = apiError.localizedDescription
        } else {
            self.error = "Nieznany błąd: \(error.localizedDescription)"
        }
    }
}

struct ResetPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ResetPasswordView(email: "test@example.com")
    }
}