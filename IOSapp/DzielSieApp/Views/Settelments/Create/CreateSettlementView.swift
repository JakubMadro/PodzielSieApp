//
//  CreateSettlementView.swift
//  DzielSieApp
//
//  Created by Kuba Mądro on 08/04/2025.
//


import SwiftUI
import Combine

struct CreateSettlementView: View {
    let groupId: String
    let groupName: String
    
    @StateObject private var viewModel = CreateSettlementViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section(header: Text("Kto komu płaci")) {
                Picker("Od", selection: $viewModel.fromUserId) {
                    ForEach(viewModel.groupMembers) { member in
                        Text(member.displayName).tag(member.id)
                    }
                }
                
                Picker("Do", selection: $viewModel.toUserId) {
                    ForEach(viewModel.groupMembers) { member in
                        Text(member.displayName).tag(member.id)
                    }
                }
            }
            
            Section(header: Text("Kwota")) {
                HStack {
                    TextField("Kwota", text: $viewModel.amountText)
                        .keyboardType(.decimalPad)
                    
                    Text(viewModel.currency)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Metoda płatności")) {
                Picker("Metoda", selection: $viewModel.paymentMethod) {
                    ForEach([PaymentMethod.manual, .blik, .paypal, .other], id: \.self) { method in
                        HStack {
                            Image(systemName: method.icon)
                            Text(method.displayName)
                        }.tag(method)
                    }
                }
                .pickerStyle(InlinePickerStyle())
                
                TextField("Referencja płatności (opcjonalnie)", text: $viewModel.paymentReference)
            }
            
            Section {
                Button(action: {
                    viewModel.createSettlement(groupId: groupId)
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Utwórz rozliczenie")
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                }
                .disabled(viewModel.isLoading || !viewModel.canSubmit)
            }
        }
        .navigationTitle("Nowe rozliczenie")
        .onAppear {
            viewModel.loadGroupMembers(groupId: groupId)
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
        .onChange(of: viewModel.settlementCreated) { created in
            if created {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

class CreateSettlementViewModel: ObservableObject {
    @Published var groupMembers: [GroupUser] = []
    @Published var fromUserId: String = ""
    @Published var toUserId: String = ""
    @Published var amountText: String = ""
    @Published var currency: String = "PLN"
    @Published var paymentMethod: PaymentMethod = .manual
    @Published var paymentReference: String = ""
    
    @Published var isLoading = false
    @Published var error: String?
    @Published var settlementCreated = false
    
    private let groupsService: GroupsServiceProtocol
    private let settlementService: CreateSettlementServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    var amount: Double {
        return Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    
    var canSubmit: Bool {
        return !fromUserId.isEmpty && !toUserId.isEmpty && fromUserId != toUserId && amount > 0
    }
    
    init(groupsService: GroupsServiceProtocol = GroupsService(),
         settlementService: CreateSettlementServiceProtocol = CreateSettlementService()) {
        self.groupsService = groupsService
        self.settlementService = settlementService
        
        // Ustaw bieżącego użytkownika jako płatnika
        if let currentUserId = AppState.shared.currentUser?.id {
            self.fromUserId = currentUserId
        }
    }
    
    func loadGroupMembers(groupId: String) {
        isLoading = true
        error = nil
        
        groupsService.fetchGroupDetails(groupId: groupId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] group in
                // Pobierz użytkowników z grupy
                let users = group.members.map { $0.user }
                self?.groupMembers = users
                self?.currency = group.defaultCurrency
                
                // Ustaw bieżącego użytkownika jako płatnika, jeśli jest członkiem grupy
                if let currentUserId = AppState.shared.currentUser?.id,
                   users.contains(where: { $0.id == currentUserId }) {
                    self?.fromUserId = currentUserId
                } else if let firstUserId = users.first?.id {
                    // Jeśli bieżący użytkownik nie jest członkiem, ustaw pierwszego użytkownika z listy
                    self?.fromUserId = firstUserId
                }
                
                // Ustaw domyślnego odbiorcę (innego niż płatnik)
                if let defaultRecipient = users.first(where: { $0.id != self?.fromUserId }) {
                    self?.toUserId = defaultRecipient.id
                }
            }
            .store(in: &cancellables)
    }
    
    func createSettlement(groupId: String) {
        guard canSubmit else { return }
        
        isLoading = true
        error = nil
        
        settlementService.createSettlement(
            groupId: groupId,
            toUserId: toUserId,
            amount: amount,
            currency: currency,
            paymentMethod: paymentMethod,
            paymentReference: paymentReference.isEmpty ? nil : paymentReference
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            self?.isLoading = false
            if case .failure(let error) = completion {
                self?.handleError(error)
            }
        } receiveValue: { [weak self] _ in
            self?.settlementCreated = true
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