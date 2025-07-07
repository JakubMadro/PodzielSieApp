//
//  GroupsView.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//

import SwiftUI

/// Ekran wyświetlający listę grup użytkownika
/// Obsługuje tworzenie nowych grup, dodawanie członków oraz archiwizację
struct GroupsView: View {
    /// ViewModel zarządzający stanem i logiką listy grup
    @StateObject private var viewModel = GroupsViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Wyświetl pusty stan gdy brak grup i nie trwa ładowanie
                if viewModel.groups.isEmpty && !viewModel.isLoading {
                    EmptyGroupsView {
                        viewModel.showCreateGroupView = true
                    }
                } else {
                    // Lista grup użytkownika
                    groupsList
                }
                
                // Wskaźnik ładowania podczas pobierania danych
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .navigationTitle("Twoje grupy")
            .navigationBarItems(trailing: addButton)
            // Pobierz grupy przy pierwszym wyświetleniu ekranu
            .onAppear {
                viewModel.fetchGroups()
            }
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
            // Modal tworzenia nowej grupy
            .sheet(isPresented: $viewModel.showCreateGroupView, onDismiss: {
                viewModel.fetchGroups() // Odśwież grupy po zamknięciu arkusza
            }) {
                CreateGroupView(viewModel: CreateGroupViewModel())
            }
            // Modal dodawania członka do grupy
            .sheet(isPresented: $viewModel.showAddMemberView, onDismiss: {
                viewModel.fetchGroups() // Odśwież grupy po zamknięciu arkusza
            }) {
                if let selectedGroup = viewModel.selectedGroup {
                    AddMemberView(group: selectedGroup)
                }
            }
            // Pull-to-refresh do odświeżenia listy grup
            .refreshable {
                viewModel.fetchGroups()
            }
        }
    }
    
    /// Przycisk dodawania nowej grupy w navigation bar
    private var addButton: some View {
        Button(action: {
            viewModel.showCreateGroupView = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .bold))
        }
    }
    
    /// Lista grup z opcjami kontekstowymi
    private var groupsList: some View {
        List {
            ForEach(viewModel.groups) { group in
                // Link do szczegółów grupy
                NavigationLink(destination: GroupDetailsView(groupId: group.id, groupName: group.name)) {
                    GroupRow(
                        group: group,
                        onEdit: {
                            viewModel.selectGroup(group)
                        },
                        onAddMember: {
                            viewModel.selectGroupForAddingMember(group)
                        },
                        onDelete: {
                            viewModel.deleteGroup(groupId: group.id)
                        }
                    )
                    // Akcje przeciągnięcia w lewo
                    .swipeActions {
                        // Archiwizacja/przywracanie grupy
                        if group.isArchived {
                            Button {
                                viewModel.archiveGroup(groupId: group.id, archive: false)
                            } label: {
                                Label("Przywróć", systemImage: "archivebox.fill")
                            }
                            .tint(.green)
                        } else {
                            Button {
                                viewModel.archiveGroup(groupId: group.id, archive: true)
                            } label: {
                                Label("Archiwizuj", systemImage: "archivebox")
                            }
                            .tint(.orange)
                        }
                        
                        // Usuwanie grupy (tylko właściciel)
                        if group.isOwner {
                            Button(role: .destructive) {
                                viewModel.selectedGroup = group
                                viewModel.showConfirmationDialog = true
                            } label: {
                                Label("Usuń", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            // Dialog potwierdzenia usunięcia grupy
            .confirmationDialog(
                "Czy na pewno chcesz usunąć tę grupę?",
                isPresented: $viewModel.showConfirmationDialog,
                titleVisibility: .visible
            ) {
                Button("Usuń", role: .destructive) {
                    if let group = viewModel.selectedGroup {
                        viewModel.deleteGroup(groupId: group.id)
                    }
                }
                Button("Anuluj", role: .cancel) {}
            } message: {
                if let group = viewModel.selectedGroup {
                    Text("Usunięcie grupy \"\(group.name)\" jest nieodwracalne.")
                }
            }
        }
    }
}

// MARK: - SwiftUI Previews
struct GroupsView_Previews: PreviewProvider {
    static var previews: some View {
        GroupsView()
    }
}
