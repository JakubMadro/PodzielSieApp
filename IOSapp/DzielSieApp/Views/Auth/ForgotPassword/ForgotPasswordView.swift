//
//  ForgotPasswordView.swift
//  DzielSieApp
//
//  Created by Claude on 06/07/2025.
//

import SwiftUI
import Combine

struct ForgotPasswordView: View {
    @StateObject private var viewModel = ForgotPasswordViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showResetPasswordView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.orange.opacity(0.6), Color.red.opacity(0.4)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 35) {
                        // Header
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "key.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.white)
                            }
                            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                            
                            VStack(spacing: 8) {
                                Text("Zapomniałeś hasła?")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Podaj swój email, a wyślemy Ci kod do resetowania hasła")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top, 60)
                        
                        // Email input
                        VStack(spacing: 25) {
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
                                    
                                    TextField("Wprowadź swój email", text: $viewModel.email)
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
                            
                            // Send button
                            Button(action: {
                                viewModel.sendResetCode()
                            }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Wyślij kod resetowania")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        
                                        Image(systemName: "paperplane.fill")
                                    }
                                }
                                .foregroundColor(viewModel.isEmailValid ? .orange : .gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                )
                            }
                            .disabled(!viewModel.isEmailValid || viewModel.isLoading)
                            .scaleEffect(viewModel.isEmailValid ? 1.0 : 0.98)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.isEmailValid)
                        }
                        .padding(.horizontal, 32)
                        
                        // Success message
                        if viewModel.isCodeSent {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                
                                Text("Kod został wysłany!")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Text("Sprawdź swoją skrzynkę email. Kod jest ważny przez 15 minut.")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Button(action: {
                                    showResetPasswordView = true
                                }) {
                                    Text("Wprowadź kod resetowania")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
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
            .fullScreenCover(isPresented: $showResetPasswordView) {
                ResetPasswordView(email: viewModel.email)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

class ForgotPasswordViewModel: ObservableObject {
    @Published var email = ""
    @Published var isLoading = false
    @Published var error: String?
    @Published var isCodeSent = false
    
    private let authService: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    var isEmailValid: Bool {
        email.contains("@") && email.contains(".") && !email.isEmpty
    }
    
    init(authService: AuthServiceProtocol = AuthService.shared) {
        self.authService = authService
    }
    
    func sendResetCode() {
        guard isEmailValid else { return }
        
        isLoading = true
        error = nil
        
        authService.forgotPassword(email: email)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] response in
                if response.success {
                    self?.isCodeSent = true
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

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}