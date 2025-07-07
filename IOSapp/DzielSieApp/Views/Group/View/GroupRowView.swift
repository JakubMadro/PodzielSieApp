//
//  GroupRow.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//

import SwiftUI
// Widok pojedynczego wiersza grupy
struct GroupRow: View {
    let group: Group
    var onEdit: (() -> Void)? = nil
    var onAddMember: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 16) {
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
                    
                    Text("\(group.memberCount) \(group.memberCount == 1 ? "osoba" : "osób")")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if group.isOwner {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("Administrator")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    if let userBalance = group.userBalance {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(formatBalance(userBalance, currency: group.defaultCurrency))
                            .font(.caption)
                            .foregroundColor(userBalance < 0 ? .red : (userBalance > 0 ? .green : .gray))
                    }
                }
            }
            
            Spacer()
            
            // Context menu dla opcji grupy
            if group.isOwner && !group.isArchived {
                Menu {
                    if let onEdit = onEdit {
                        Button(action: onEdit) {
                            Label("Edytuj", systemImage: "pencil")
                        }
                    }
                    
                    if let onAddMember = onAddMember {
                        Button(action: onAddMember) {
                            Label("Dodaj członka", systemImage: "person.badge.plus")
                        }
                    }
                    
                    if let onDelete = onDelete {
                        Button(role: .destructive, action: onDelete) {
                            Label("Usuń", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.gray)
                    .padding(8)
                }
            }
        }
        .padding(.vertical, 8)
        .opacity(group.isArchived ? 0.6 : 1.0)
    }
    
    private func formatBalance(_ balance: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        
        if let formattedValue = formatter.string(from: NSNumber(value: abs(balance))) {
            return balance < 0 ? "-\(formattedValue)" : (balance > 0 ? "+\(formattedValue)" : formattedValue)
        }
        
        return balance < 0 ? "-\(abs(balance)) \(currency)" : "+\(balance) \(currency)"
    }
}
