// APIEndpoint.swift
import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum APIEndpoint {
    // Autentykacja
    case login(email: String, password: String)
    case register(user: RegistrationData)
    case forgotPassword(email: String)
    case resetPassword(token: String, newPassword: String, confirmPassword: String)
    
    // Grupy
    case getGroups
    case getGroupDetails(groupId: String)
    case createGroup(name: String, description: String?, defaultCurrency: String?)
    case updateGroup(groupId: String, name: String?, description: String?, defaultCurrency: String?)
    case addGroupMember(groupId: String, email: String, role: String?)
    case removeGroupMember(groupId: String, userId: String)
    case updateMemberRole(groupId: String, userId: String, role: String)
    case archiveGroup(groupId: String, archive: Bool)
    case deleteGroup(groupId: String)
    case getUserBalance(groupId: String)
    case getGroupBalances(groupId: String)
    
    // Wydatki
    case createExpense(expenseData: ExpenseCreateData)
    case getGroupExpenses(groupId: String, page: Int?, limit: Int?)
    case getExpenseDetails(expenseId: String)
    case updateExpense(expenseId: String, updateData: [String: Any])
    case deleteExpense(expenseId: String)
    case addExpenseComment(expenseId: String, text: String)
    
    // Rozliczenia
    case getPendingSettlements
    case getCompletedSettlements
    case getAllSettlements
    
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
    
    var method: HTTPMethod {
        switch self {
        // POST
        case .login, .register, .forgotPassword, .resetPassword, .createGroup, .addGroupMember, .createExpense, .addExpenseComment:
            return .post
            
        // PUT
        case .updateGroup, .updateMemberRole, .archiveGroup, .updateExpense:
            return .put
            
        // GET
        case .getGroups, .getGroupDetails, .getGroupExpenses, .getExpenseDetails, .getUserBalance, .getGroupBalances, .getPendingSettlements, .getCompletedSettlements, .getAllSettlements:
            return .get
        
            
        // DELETE
        case .removeGroupMember, .deleteGroup, .deleteExpense:
            return .delete
        }
    }
    
    var body: [String: Any]? {
        switch self {
        case .login(let email, let password):
            return ["email": email, "password": password]
            
        case .register(let user):
            // Dla obiektu RegistrationData musimy zapewnić niestandardową konwersję
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
