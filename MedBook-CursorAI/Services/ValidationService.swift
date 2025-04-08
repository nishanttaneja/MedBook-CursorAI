import Foundation

class ValidationService {
    static let shared = ValidationService()
    
    private init() {}
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func isValidPassword(_ password: String) -> (isValid: Bool, message: String?) {
        if password.count < 8 {
            return (false, "Password must be at least 8 characters long")
        }
        
        let numberRegEx = ".*[0-9]+.*"
        let numberPred = NSPredicate(format:"SELF MATCHES %@", numberRegEx)
        if !numberPred.evaluate(with: password) {
            return (false, "Password must contain at least 1 number")
        }
        
        let uppercaseRegEx = ".*[A-Z]+.*"
        let uppercasePred = NSPredicate(format:"SELF MATCHES %@", uppercaseRegEx)
        if !uppercasePred.evaluate(with: password) {
            return (false, "Password must contain at least 1 uppercase character")
        }
        
        let specialCharRegEx = ".*[!@#$%^&*(),.?\":{}|<>]+.*"
        let specialCharPred = NSPredicate(format:"SELF MATCHES %@", specialCharRegEx)
        if !specialCharPred.evaluate(with: password) {
            return (false, "Password must contain at least 1 special character")
        }
        
        return (true, nil)
    }
} 