//
//  GroupDetailsView.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 06/04/2025.
//

import SwiftUI
import Combine

struct GroupDetailsView: View {
    let groupId: String
    let groupName: String
    
    @StateObject private var viewModel = GroupDetailsViewModel()
    @State private var showAddMemberSheet = false
    @State private var showConfirmationDialog = false
    @State private var showArchiveConfirmation = false
    @State private var showAddExpenseSheet = false
    
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle())
            } else if let group = viewModel.group {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Nagłówek grupy
                        GroupHeaderView(group: group)
                        
                        
                        // Przyciski szybkich akcji
                        HStack(spacing: 15) {
                            Button(action: {
                                showAddExpenseSheet = true
                            }) {
                                VStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.blue)
                                    Text("Dodaj wydatek")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                            }
                            
                            NavigationLink(destination: GroupExpensesView(groupId: group.id, groupName: group.name)) {
                                VStack {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.green)
                                    Text("Wydatki")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Przycisk do rozliczeń grupy
                        NavigationLink(destination: GroupBalanceView(groupId: group.id, groupName: group.name)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Rozliczenia grupy")
                                        .font(.headline)
                                    
                                    Text("Sprawdź bilans i rozlicz się ze znajomymi")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.left.arrow.right.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                        
                        // Członkowie grupy
                        MembersListView(
                            members: group.members,
                            isAdmin: group.isOwner,
                            onAddMember: { showAddMemberSheet = true },
                            onRemoveMember: viewModel.removeMember
                        )
                        
                        // Przyciski akcji (jeśli jest admin)
                        if group.isOwner {
                            GroupAdminActionsView(
                                isArchived: group.isArchived,
                                onArchive: { showArchiveConfirmation = true },
                                onDelete: { showConfirmationDialog = true }
                            )
                        }
                    }
                    .padding()
                }
                .navigationTitle(group.name)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: Button(action: {
                    viewModel.fetchGroupDetails()
                }) {
                    Image(systemName: "arrow.clockwise")
                })
                .sheet(isPresented: $showAddMemberSheet) {
                    if let group = viewModel.group {
                        AddMemberView(group: group)
                    }
                }
                .sheet(isPresented: $showAddExpenseSheet) {
                    CreateExpenseView(groupId: group.id)
                }
                .alert(isPresented: $showArchiveConfirmation) {
                    let title = group.isArchived ? "Przywrócić grupę?" : "Zarchiwizować grupę?"
                    let message = group.isArchived
                        ? "Czy na pewno chcesz przywrócić tę grupę? Będzie ona znów widoczna na liście aktywnych grup."
                        : "Czy na pewno chcesz zarchiwizować tę grupę? Będzie ona ukryta na liście aktywnych grup."
                    
                    return Alert(
                        title: Text(title),
                        message: Text(message),
                        primaryButton: .destructive(Text(group.isArchived ? "Przywróć" : "Zarchiwizuj")) {
                            viewModel.toggleArchive()
                        },
                        secondaryButton: .cancel()
                    )
                }
                .confirmationDialog(
                    "Czy na pewno chcesz usunąć tę grupę?",
                    isPresented: $showConfirmationDialog,
                    titleVisibility: .visible
                ) {
                    Button("Usuń", role: .destructive) {
                        viewModel.deleteGroup()
                    }
                    Button("Anuluj", role: .cancel) {}
                } message: {
                    Text("Usunięcie grupy \"\(group.name)\" jest nieodwracalne.")
                }
            } else {
                if let error = viewModel.error {
                    VStack {
                        Text("Wystąpił błąd:")
                            .font(.headline)
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button(action: {
                            viewModel.fetchGroupDetails()
                        }) {
                            Text("Spróbuj ponownie")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    VStack {
                        Text("Ładowanie danych grupy...")
                        ProgressView()
                    }
                }
            }
        }
        .onAppear {
            viewModel.groupId = groupId
            viewModel.fetchGroupDetails()
        }
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
}

// MARK: - Pomocnicze komponenty

struct GroupHeaderView: View {
    let group: Group
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(group.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                if group.isArchived {
                    HStack {
                        Image(systemName: "archivebox.fill")
                        Text("Zarchiwizowana")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            
            if let description = group.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Label("\(group.members.count) \(group.members.count == 1 ? "osoba" : "osób")", systemImage: "person.2.fill")
                Spacer()
                Label(group.defaultCurrency, systemImage: "creditcard.fill")
            }
            .font(.caption)
            .foregroundColor(.gray)
            
            Divider()
        }
    }
}

struct MembersListView: View {
    let members: [GroupMember]
    let isAdmin: Bool
    let onAddMember: () -> Void
    let onRemoveMember: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Członkowie grupy")
                    .font(.headline)
                
                Spacer()
                
                if isAdmin {
                    Button(action: onAddMember) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Dodaj")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
            
            ForEach(members) { member in
                HStack {
                    // Avatar lub inicjały
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Text(member.user.initials)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    
                    // Dane członka
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.user.displayName)
                            .font(.system(size: 16, weight: .medium))
                        
                        Text(member.user.email)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Odznaka roli
                    if member.role == "admin" {
                        Text("Admin")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    
                    // Przycisk usuwania (tylko dla adminów i nie dla siebie)
                    if isAdmin && member.user.id != AppState.shared.currentUser?.id {
                        Button(action: {
                            onRemoveMember(member.user.id)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .padding(8)
                        }
                    }
                }
                .padding(.vertical, 6)
                
                if member.id != members.last?.id {
                    Divider()
                }
            }
            
            Divider()
        }
    }
}

struct GroupAdminActionsView: View {
    let isArchived: Bool
    let onArchive: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Akcje administratora")
                .font(.headline)
            
            VStack(spacing: 12) {
                Button(action: onArchive) {
                    HStack {
                        Image(systemName: isArchived ? "archivebox.fill" : "archivebox")
                        Text(isArchived ? "Przywróć grupę" : "Zarchiwizuj grupę")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .foregroundColor(.primary)
                }
                
                Button(action: onDelete) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Usuń grupę")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .foregroundColor(.red)
                }
            }
        }
    }
}
