//
//  ActivityComponents.swift
//  DzielSieApp
//
//  Created by Claude on 06/04/2025.
//

import SwiftUI

struct RecentActivitiesSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ostatnie aktywności")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    viewModel.fetchRecentActivities()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            if viewModel.isLoading && viewModel.activities.isEmpty {
                VStack {
                    ProgressView()
                        .padding()
                    Text("Ładowanie aktywności...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            } else if viewModel.activities.isEmpty {
                EmptyActivitiesView()
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    ForEach(viewModel.activities) { activity in
                        ActivityRow(activity: activity)
                    }
                }
                .frame(maxHeight: 300)
            }
        }
        .padding(.top, 20)
    }
}

struct EmptyActivitiesView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 30))
                .foregroundColor(.gray.opacity(0.7))
                .padding()
            
            Text("Brak aktywności")
                .font(.headline)
            
            Text("Tu będą wyświetlane Twoje najnowsze aktywności związane z wydatkami i grupami")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ActivityRow: View {
    let activity: Activity
    
    var body: some View {
        NavigationLink(destination: getDestinationView()) {
            HStack(spacing: 12) {
                // Icon for the activity
                Image(systemName: activity.iconName)
                    .font(.title3)
                    .foregroundColor(getIconColor(for: activity.type))
                    .frame(width: 40, height: 40)
                    .background(getIconColor(for: activity.type).opacity(0.2))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title)
                        .font(.subheadline)
                        .lineLimit(1)
                    
                    Text(activity.subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if let formattedAmount = activity.formattedAmount {
                    Text(formattedAmount)
                        .font(.subheadline)
                        .foregroundColor(getAmountColor(for: activity))
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Determine icon color based on activity type
    private func getIconColor(for type: ActivityType) -> Color {
        switch type {
        case .newExpense:
            return .blue
        case .addedToGroup:
            return .green
        case .settledExpense:
            return .purple
        case .groupCreated:
            return .indigo
        case .memberAdded:
            return .orange
        }
    }
    
    // Determine color for amount display
    private func getAmountColor(for activity: Activity) -> Color {
        guard let amount = activity.amount else { return .primary }
        
        if activity.type == .newExpense {
            // If current user is the payer, it's red (expense)
            // Otherwise, it would be green (someone else paid)
            let isUserPayer = activity.title.hasPrefix("Dodałeś")
            return isUserPayer ? .red : .green
        }
        
        return amount < 0 ? .red : .green
    }
    
    // Return the appropriate destination view based on activity type
    @ViewBuilder
    private func getDestinationView() -> some View {
        if let expenseId = activity.expenseId, let groupId = activity.groupId {
            // In a real app, this would navigate to expense details
            // For now, we'll just navigate to group expenses
            GroupExpensesView(groupId: groupId, groupName: "Grupa")
        } else if let groupId = activity.groupId {
            // Navigate to group details
            GroupDetailsView(groupId: groupId, groupName: "Grupa")
        } else {
            // Fallback to empty view
            EmptyView()
        }
    }
}
