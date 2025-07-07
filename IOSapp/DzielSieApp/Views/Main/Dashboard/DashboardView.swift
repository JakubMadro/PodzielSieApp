//
//  DashboardView.swift
//  DzielSieApp
//
//  Created by Claude on 06/04/2025.
//

import SwiftUI
import Combine

/// Główny ekran dashboardu z przeglądem aktywności i szybkimi akcjami
/// Wyświetla powitanie użytkownika, szybkie akcje oraz ostatnie aktywności
struct DashboardView: View {
    /// Globalny stan aplikacji z danymi zalogowanego użytkownika
    @EnvironmentObject var appState: AppState
    
    /// ViewModel zarządzający logiką dashboardu
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Nagłówek z powitaniem zalogowanego użytkownika
                    if let user = appState.currentUser {
                        UserWelcomeHeader(user: user)
                            .padding(.top, 20)
                    }
                    
                    // Siatka szybkich akcji (nowa grupa, dodaj wydatek)
                    QuickActionsGrid()
                        .padding(.horizontal)
                    
                    // Sekcja z ostatnimi aktywnościami w grupach
                    RecentActivitiesSection(viewModel: viewModel)
                    
                    Spacer()
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Pulpit")
            .navigationBarTitleDisplayMode(.inline)
            // Alert z komunikatami błędów
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
            // Pobierz dane przy pierwszym wyświetleniu
            .onAppear {
                viewModel.fetchRecentActivities()
            }
            // Odśwież dane przy przeciągnięciu w dół
            .refreshable {
                viewModel.fetchRecentActivities()
            }
        }
    }
}

/// Nagłówek powitalny z awatarem i imieniem użytkownika
struct UserWelcomeHeader: View {
    /// Dane użytkownika do wyświetlenia
    let user: User
    
    var body: some View {
        VStack(spacing: 16) {
            // Okrągły awatar z gradientem i inicjałami
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                
                // Inicjały użytkownika (pierwsza litera imienia i nazwiska)
                Text(user.initials)
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            
            // Tekst powitalny z imieniem i nazwiskiem
            VStack(spacing: 4) {
                Text("Witaj z powrotem")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("\(user.firstName) \(user.lastName)")
                    .font(.title3.bold())
            }
        }
    }
}

/// Siatka szybkich akcji na dashboardzie
struct QuickActionsGrid: View {
    /// Czy pokazać ekran tworzenia nowej grupy
    @State private var navigateToCreateGroup = false
    
    /// Czy pokazać ekran wyboru grupy dla wydatku
    @State private var showExpenseGroupSelection = false
    
    /// Czy pokazać ekran tworzenia wydatku
    @State private var navigateToCreateExpense = false
    
    /// ID wybranej grupy dla nowego wydatku
    @State private var selectedGroupId: String?
    
    var body: some View {
        // Siatka 2x1 z przyciskami szybkich akcji
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible())], spacing: 16) {
            // Przycisk tworzenia nowej grupy
            QuickActionCard(action: QuickAction(icon: "plus.circle.fill", title: "Nowa grupa", color: .green))
                .onTapGesture {
                    navigateToCreateGroup = true
                }
            
            // Przycisk dodawania wydatku
            QuickActionCard(action: QuickAction(icon: "creditcard.fill", title: "Dodaj wydatek", color: .orange))
                .onTapGesture {
                    showExpenseGroupSelection = true
                }
        }
        // Modal tworzenia nowej grupy
        .sheet(isPresented: $navigateToCreateGroup) {
            let viewModel = CreateGroupViewModel()
            CreateGroupView(viewModel: viewModel)
        }
        // Modal wyboru grupy dla wydatku
        .sheet(isPresented: $showExpenseGroupSelection) {
            GroupSelectionView(
                onGroupSelect: { group in
                    showExpenseGroupSelection = false
                    selectedGroupId = group.id
                    navigateToCreateExpense = true
                },
                onCancel: {
                    showExpenseGroupSelection = false
                }
            )
        }
        // Modal tworzenia wydatku dla wybranej grupy
        .sheet(isPresented: $navigateToCreateExpense) {
            if let groupId = selectedGroupId {
                CreateExpenseView(groupId: groupId)
            }
        }
    }
}


/// Karta szybkiej akcji z ikoną i opisem
struct QuickActionCard: View {
    /// Dane akcji do wyświetlenia
    let action: QuickAction
    
    var body: some View {
        VStack(spacing: 8) {
            // Ikona w kołku z kolorem akcji
            Image(systemName: action.icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(action.color)
                .frame(width: 44, height: 44)
                .background(action.color.opacity(0.2))
                .clipShape(Circle())
            
            // Tytuł akcji
            Text(action.title)
                .font(.system(size: 14, weight: .medium))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

/// Model danych dla szybkiej akcji
struct QuickAction {
    /// Nazwa ikony SF Symbols
    let icon: String
    
    /// Tytuł akcji
    let title: String
    
    /// Kolor akcji
    let color: Color
}


// MARK: - SwiftUI Previews
/// Podgląd dla DashboardView z przykładowymi danymi
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState.shared
        appState.currentUser = User(id: "1", firstName: "Jan", lastName: "Kowalski", email: "jan@example.com")
        
        return DashboardView()
            .environmentObject(appState)
    }
}
