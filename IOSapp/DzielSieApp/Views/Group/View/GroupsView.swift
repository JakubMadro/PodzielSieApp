//
//  GroupsView.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//

import SwiftUI

struct GroupsView: View {
    @StateObject private var viewModel = GroupsViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.groups.isEmpty && !viewModel.isLoading {
                    EmptyGroupsView {
                        viewModel.showCreateGroupView = true
                    }
                } else {
                    groupsList
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .navigationTitle("Twoje grupy")
            .navigationBarItems(trailing: addButton)
            .onAppear {
                viewModel.fetchGroups()
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
            .sheet(isPresented: $viewModel.showCreateGroupView, onDismiss: {
                viewModel.fetchGroups() // Odśwież grupy po zamknięciu arkusza
            }) {
                CreateGroupView(viewModel: CreateGroupViewModel())
            }
            .sheet(isPresented: $viewModel.showAddMemberView, onDismiss: {
                viewModel.fetchGroups() // Odśwież grupy po zamknięciu arkusza
            }) {
                if let selectedGroup = viewModel.selectedGroup {
                    AddMemberView(group: selectedGroup)
                }
            }
            .refreshable {
                viewModel.fetchGroups()
            }
        }
    }
    
    private var addButton: some View {
        Button(action: {
            viewModel.showCreateGroupView = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .bold))
        }
    }
    
    private var groupsList: some View {
        List {
            ForEach(viewModel.groups) { group in
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
                    .swipeActions {
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
