//
//  SettlementsView.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 07/04/2025.
//


import SwiftUI

struct SettlementsView: View {
    @StateObject private var viewModel = SettlementsViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom segment control
                CustomSegmentControl(
                    selectedIndex: $selectedTab,
                    options: ["Oczekujące", "Historia"]
                )
                .padding()
                .onChange(of: selectedTab) { newTab in
                    if newTab == 1 {
                        // Załaduj historię gdy użytkownik przełączy na zakładkę "Historia"
                        viewModel.loadCompletedSettlements()
                    }
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    TabView(selection: $selectedTab) {
                        // Zakładka "Oczekujące"
                        pendingSettlementsView
                            .tag(0)
                        
                        // Zakładka "Historia"
                        settlementHistoryView
                            .tag(1)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Rozliczenia")
            .navigationBarItems(trailing: Button(action: {
                viewModel.loadData()
            }) {
                Image(systemName: "arrow.clockwise")
            })
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
                viewModel.loadData()
            }
        }
    }
    
    // Widok oczekujących rozliczeń
    private var pendingSettlementsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.pendingSettlements.isEmpty {
                    emptyPendingView
                } else {
                    ForEach(viewModel.pendingSettlements) { settlement in
                        NavigationLink(destination: SettlementDetailView(settlementId: settlement.id)) {
                            SettlementCardView(settlement: settlement, isPending: true)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
        }
        .refreshable {
            viewModel.loadData()
        }
    }
    
    // Widok historii rozliczeń
    private var settlementHistoryView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.settlementHistory.isEmpty {
                    emptyHistoryView
                } else {
                    ForEach(viewModel.settlementHistory) { settlement in
                        NavigationLink(destination: SettlementDetailView(settlementId: settlement.id)) {
                            SettlementCardView(settlement: settlement, isPending: false)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
        }
        .refreshable {
            viewModel.loadCompletedSettlements()
        }
    }
    
    // Widok pustej listy oczekujących rozliczeń
    private var emptyPendingView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Brak oczekujących rozliczeń")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Wszystkie Twoje długi są rozliczone.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // Widok pustej historii rozliczeń
    private var emptyHistoryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Brak historii rozliczeń")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Tu będą wyświetlane Twoje zakończone rozliczenia.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// Custom segment control
struct CustomSegmentControl: View {
    @Binding var selectedIndex: Int
    let options: [String]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring()) {
                        selectedIndex = index
                    }
                }) {
                    Text(options[index])
                        .fontWeight(selectedIndex == index ? .bold : .regular)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(selectedIndex == index ? .white : .primary)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedIndex == index ? Color.blue : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// Widok karty rozliczenia
struct SettlementCardView: View {
    let settlement: Settlement
    let isPending: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Ikona statusu
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                
                Spacer()
                
                // Data
                Text(formatDate(settlement.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Informacje o rozliczeniu
            HStack(alignment: .center) {
                // Nadawca
                VStack(alignment: .center, spacing: 4) {
                    UserAvatarView(user: settlement.payer)
                    
                    Text(settlement.payer.firstName)
                        .font(.subheadline)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Strzałka i kwota
                VStack(spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(.title3)
                        .foregroundColor(.blue)
                    
                    Text(formatAmount(settlement.amount, currency: settlement.currency))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Odbiorca
                VStack(alignment: .center, spacing: 4) {
                    UserAvatarView(user: settlement.receiver)
                    
                    Text(settlement.receiver.firstName)
                        .font(.subheadline)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 8)
            
            // Grupa
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Text("Grupa: \(settlement.group)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Metoda płatności (jeśli jest)
                if let method = settlement.paymentMethod {
                    HStack(spacing: 4) {
                        Image(systemName: methodIcon(method))
                            .font(.caption)
                        
                        Text(method.displayName)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // Status rozliczenia
    private var statusIcon: String {
        settlement.status.icon
    }
    
    private var statusColor: Color {
        switch settlement.status.color {
        case "green":
            return .green
        case "yellow":
            return .yellow
        case "red":
            return .red
        default:
            return .gray
        }
    }
    
    // Ikona metody płatności
    private func methodIcon(_ method: PaymentMethod) -> String {
        return method.icon
    }
    
    // Formatowanie daty
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Formatowanie kwoty
    private func formatAmount(_ amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
    }
}

// Widok avatara użytkownika
struct UserAvatarView: View {
    let user: User
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
            
            Text(getInitials())
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.blue)
        }
    }
    
    private func getInitials() -> String {
        let firstInitial = user.firstName.prefix(1).uppercased()
        let lastInitial = user.lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }
}

// Preview
struct SettlementsView_Previews: PreviewProvider {
    static var previews: some View {
        SettlementsView()
    }
}
