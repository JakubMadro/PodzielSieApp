//
//  GroupSelectionView.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 06/04/2025.
//


import SwiftUI
import Combine

struct GroupSelectionView: View {
    @StateObject private var viewModel: GroupSelectionViewModel
    let onGroupSelect: (Group) -> Void
    let onCancel: () -> Void
    
    init(
        groupsService: GroupsServiceProtocol = GroupsService(),
        onGroupSelect: @escaping (Group) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: GroupSelectionViewModel(groupsService: groupsService))
        self.onGroupSelect = onGroupSelect
        self.onCancel = onCancel
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Ładowanie grup...")
                } else {
                    groupsList
                }
            }
            .navigationTitle("Wybierz grupę")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Anuluj") {
                onCancel()
            })
            .onAppear {
                viewModel.loadGroups()
            }
        }
    }
    
    private var groupsList: some View {
        List {
            ForEach(viewModel.groups) { group in
                GroupSelectionRow(group: group)
                    .onTapGesture {
                        onGroupSelect(group)
                    }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

struct GroupSelectionRow: View {
    let group: Group
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar grupy
            ZStack {
                Circle()
                    .fill(group.isArchived ? Color.gray.opacity(0.3) : Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text(String(group.name.prefix(1)).uppercased())
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(group.isArchived ? .gray : .blue)
            }
            
            // Informacje o grupie
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(group.name)
                        .font(.headline)
                    
                    if group.isArchived {
                        Image(systemName: "archivebox")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(group.members.count) \(group.members.count == 1 ? "osoba" : "osób")")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
        .opacity(group.isArchived ? 0.6 : 1.0)
    }
}
