// APIEndpoint.swift
import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// Enum definiujący wszystkie endpointy API aplikacji
/// Każdy case zawiera parametry potrzebne do wykonania żądania
enum APIEndpoint {
    // MARK: - Autentykacja
    /// Logowanie użytkownika
    case login(email: String, password: String)
    
    /// Rejestracja nowego użytkownika
    case register(user: RegistrationData)
    
    /// Resetowanie hasła - wysyłanie linku na email
    case forgotPassword(email: String)
    
    /// Resetowanie hasła - ustawianie nowego hasła
    case resetPassword(token: String, newPassword: String, confirmPassword: String)
    
    // MARK: - Grupy
    /// Pobranie listy grup użytkownika
    case getGroups
    
    /// Pobranie szczegółów konkretnej grupy
    case getGroupDetails(groupId: String)
    
    /// Tworzenie nowej grupy
    case createGroup(name: String, description: String?, defaultCurrency: String?)
    
    /// Aktualizacja danych grupy
    case updateGroup(groupId: String, name: String?, description: String?, defaultCurrency: String?)
    
    /// Dodanie nowego członka do grupy
    case addGroupMember(groupId: String, email: String, role: String?)
    
    /// Usunięcie członka z grupy
    case removeGroupMember(groupId: String, userId: String)
    
    /// Aktualizacja roli członka w grupie
    case updateMemberRole(groupId: String, userId: String, role: String)
    
    /// Archiwizacja/przywracanie grupy
    case archiveGroup(groupId: String, archive: Bool)
    
    /// Usunięcie grupy
    case deleteGroup(groupId: String)
    
    /// Pobranie salda użytkownika w grupie
    case getUserBalance(groupId: String)
    
    /// Pobranie sald wszystkich członków grupy
    case getGroupBalances(groupId: String)
    
    // MARK: - Wydatki
    /// Tworzenie nowego wydatku
    case createExpense(expenseData: ExpenseCreateData)
    
    /// Pobranie wydatków grupy z paginacją
    case getGroupExpenses(groupId: String, page: Int?, limit: Int?)
    
    /// Pobranie szczegółów wydatku
    case getExpenseDetails(expenseId: String)
    
    /// Aktualizacja wydatku
    case updateExpense(expenseId: String, updateData: [String: Any])
    
    /// Usunięcie wydatku
    case deleteExpense(expenseId: String)
    
    /// Dodanie komentarza do wydatku
    case addExpenseComment(expenseId: String, text: String)
    
    // MARK: - Rozliczenia
    /// Pobranie oczekujących rozliczeń
    case getPendingSettlements
    
    /// Pobranie zakończonych rozliczeń
    case getCompletedSettlements
    
    /// Pobranie wszystkich rozliczeń
    case getAllSettlements
    
    /// Zwraca ścieżkę URL dla danego endpointu
    var path: String {
        switch self {
        // Autentykacja
        case .login:
            return "/auth/login"
        case .register:
            return "/auth/register"
        case .forgotPassword:
            return "/auth/forgot-password"
        case .resetPassword:
            return "/auth/reset-password"
        
        // Grupy
        case .getGroups:
            return "/groups"
        case .getGroupDetails(let groupId):
            return "/groups/\(groupId)"
        case .createGroup:
            return "/groups"
        case .updateGroup(let groupId, _, _, _):
            return "/groups/\(groupId)"
        case .addGroupMember(let groupId, _, _):
            return "/groups/\(groupId)/members"
        case .removeGroupMember(let groupId, let userId):
            return "/groups/\(groupId)/members/\(userId)"
        case .updateMemberRole(let groupId, let userId, _):
            return "/groups/\(groupId)/members/\(userId)/role"
        case .archiveGroup(let groupId, _):
            return "/groups/\(groupId)/archive"
        case .deleteGroup(let groupId):
            return "/groups/\(groupId)"
        case .getUserBalance(let groupId):
            return "/groups/\(groupId)/my-balance"
        case .getGroupBalances(let groupId):  // NOWA ŚCIEŻKA
                    return "/groups/\(groupId)/balances"
            
        // Wydatki
        case .createExpense:
            return "/expenses"
        case .getGroupExpenses(let groupId, _, _):
            return "/groups/\(groupId)/expenses"
        case .getExpenseDetails(let expenseId):
            return "/expenses/\(expenseId)"
        case .updateExpense(let expenseId, _):
            return "/expenses/\(expenseId)"
        case .deleteExpense(let expenseId):
            return "/expenses/\(expenseId)"
        case .addExpenseComment(let expenseId, _):
            return "/expenses/\(expenseId)/comments"
            
        // Rozliczenia
        case .getPendingSettlements:
            return "/settlements/pending"
        case .getCompletedSettlements:
            return "/settlements/completed"
        case .getAllSettlements:
            return "/settlements"
        }
    }
    
    /// Zwraca metodę HTTP dla danego endpointu
    var method: HTTPMethod {
        switch self {
        // POST - tworzenie nowych zasobów
        case .login, .register, .forgotPassword, .resetPassword, .createGroup, .addGroupMember, .createExpense, .addExpenseComment:
            return .post
            
        // PUT - aktualizacja istniejących zasobów
        case .updateGroup, .updateMemberRole, .archiveGroup, .updateExpense:
            return .put
            
        // GET - pobieranie danych
        case .getGroups, .getGroupDetails, .getGroupExpenses, .getExpenseDetails, .getUserBalance, .getGroupBalances, .getPendingSettlements, .getCompletedSettlements, .getAllSettlements:
            return .get
        
        // DELETE - usuwanie zasobów
        case .removeGroupMember, .deleteGroup, .deleteExpense:
            return .delete
        }
    }
    
    /// Zwraca ciało żądania HTTP (body) dla danego endpointu
    var body: [String: Any]? {
        switch self {
        case .login(let email, let password):
            return ["email": email, "password": password]
            
        case .register(let user):
            // Konwersja obiektu RegistrationData na słownik
            let encoder = JSONEncoder()
            guard let data = try? encoder.encode(user),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }
            return dict
            
        case .createGroup(let name, let description, let defaultCurrency):
            var params: [String: Any] = ["name": name]
            if let description = description, !description.isEmpty {
                params["description"] = description
            }
            if let defaultCurrency = defaultCurrency {
                params["defaultCurrency"] = defaultCurrency
            }
            return params
            
        case .updateGroup(_, let name, let description, let defaultCurrency):
            var params: [String: Any] = [:]
            if let name = name {
                params["name"] = name
            }
            if let description = description {
                params["description"] = description
            }
            if let defaultCurrency = defaultCurrency {
                params["defaultCurrency"] = defaultCurrency
            }
            return params
            
        case .addGroupMember(_, let email, let role):
            var params: [String: Any] = [
                "email": email
            ]
            if let role = role {
                params["role"] = role
            }
            return params
            
        case .updateMemberRole(_, _, let role):
            return ["role": role]
            
        case .archiveGroup(_, let archive):
            return ["isArchived": archive]
            
        case .createExpense(let expenseData):
            // Dla ExpenseCreateData musimy zapewnić niestandardową konwersję
            let encoder = JSONEncoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            encoder.dateEncodingStrategy = .formatted(dateFormatter)
            
            guard let data = try? encoder.encode(expenseData),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }
            return dict
            
        case .updateExpense(_, let updateData):
            return updateData
            
        case .addExpenseComment(_, let text):
            return ["text": text]
            
        case .forgotPassword(let email):
            return ["email": email]
            
        case .resetPassword(let token, let newPassword, let confirmPassword):
            return [
                "token": token,
                "newPassword": newPassword,
                "confirmPassword": confirmPassword
            ]
            
        default:
            return nil
        }
    }
    
    var queryParameters: [String: String]? {
        switch self {
        case .getGroupExpenses(_, let page, let limit):
            var params: [String: String] = [:]
            
            if let page = page {
                params["page"] = "\(page)"
            }
            
            if let limit = limit {
                params["limit"] = "\(limit)"
            }
            
            return params.isEmpty ? nil : params
            
        default:
            return nil
        }
    }
    
    var requiresAuthentication: Bool {
        switch self {
        case .login, .register, .forgotPassword, .resetPassword:
            return false
        default:
            return true
        }
    }
}
