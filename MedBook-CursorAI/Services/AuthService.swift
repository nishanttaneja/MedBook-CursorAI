import Foundation
import CoreData

class AuthService {
    static let shared = AuthService()
    
    private init() {}
    
    private let userDefaults = UserDefaults.standard
    private let isLoggedInKey = "isLoggedIn"
    private let userEmailKey = "userEmail"
    
    var isLoggedIn: Bool {
        get { userDefaults.bool(forKey: isLoggedInKey) }
        set { userDefaults.set(newValue, forKey: isLoggedInKey) }
    }
    
    var currentUserEmail: String? {
        get { userDefaults.string(forKey: userEmailKey) }
        set { userDefaults.set(newValue, forKey: userEmailKey) }
    }
    
    func signUp(email: String, password: String, country: Country) throws {
        let context = CoreDataManager.shared.context
        
        // Check if user already exists
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "email == %@", email)
        
        if let existingUser = try context.fetch(fetchRequest).first {
            throw AuthError.userAlreadyExists
        }
        
        // Create new user
        let user = User(context: context)
        user.email = email
        user.password = password
        user.country = country
        
        try context.save()
        
        // Set login state
        isLoggedIn = true
        currentUserEmail = email
    }
    
    func login(email: String, password: String) throws {
        let context = CoreDataManager.shared.context
        
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "email == %@ AND password == %@", email, password)
        
        guard let user = try context.fetch(fetchRequest).first else {
            throw AuthError.invalidCredentials
        }
        
        // Set login state
        isLoggedIn = true
        currentUserEmail = user.email
    }
    
    func logout() {
        isLoggedIn = false
        currentUserEmail = nil
    }
}

enum AuthError: Error {
    case userAlreadyExists
    case invalidCredentials
} 