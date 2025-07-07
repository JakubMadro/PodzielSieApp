//
//  DashboardView.swift
//  DzielSieApp
//
//  Created by Claude on 06/04/2025.
//

import SwiftUI
import Combine

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Nagłówek z użytkownikiem
                    if let user = appState.currentUser {
                        UserWelcomeHeader(user: user)
                            .padding(.top, 20)
                    }
                    
                    // Szybkie akcje
                    QuickActionsGrid()
                        .padding(.horizontal)
                    
                    // Ostatnie aktywności
                    RecentActivitiesSection(viewModel: viewModel)
                    
                    Spacer()
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Pulpit")
            .navigationBarTitleDisplayMode(.inline)
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
            .onAppear {
                viewModel.fetchRecentActivities()
            }
            .refreshable {
                viewModel.fetchRecentActivities()
            }
        }
    }
}

struct UserWelcomeHeader: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                
                Text(user.initials)
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            
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

struct QuickActionsGrid: View {
    @State private var navigateToCreateGroup = false
    @State private var showExpenseGroupSelection = false
    @State private var navigateToCreateExpense = false
    @State private var selectedGroupId: String?
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible())], spacing: 16) {
            QuickActionCard(action: QuickAction(icon: "plus.circle.fill", title: "Nowa grupa", color: .green))
                .onTapGesture {
                    navigateToCreateGroup = true
                }
            
            QuickActionCard(action: QuickAction(icon: "creditcard.fill", title: "Dodaj wydatek", color: .orange))
                .onTapGesture {
                    showExpenseGroupSelection = true
                }
        }
        .sheet(isPresented: $navigateToCreateGroup) {
            let viewModel = CreateGroupViewModel()
            CreateGroupView(viewModel: viewModel)
        }
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
        .sheet(isPresented: $navigateToCreateExpense) {
            if let groupId = selectedGroupId {
                CreateExpenseView(groupId: groupId)
            }
        }
    }
}


struct QuickActionCard: View {
    let action: QuickAction
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: action.icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(action.color)
                .frame(width: 44, height: 44)
                .background(action.color.opacity(0.2))
                .clipShape(Circle())
            
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

struct QuickAction {
    let icon: String
    let title: String
    let color: Color
}


// Extension do podglądu
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState.shared
        appState.currentUser = User(id: "1", firstName: "Jan", lastName: "Kowalski", email: "jan@example.com")
        
        return DashboardView()
            .environmentObject(appState)
    }
}
