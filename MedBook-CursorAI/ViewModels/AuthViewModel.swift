import Foundation
import CoreData

class AuthViewModel {
    private let authService = AuthService.shared
    private let validationService = ValidationService.shared
    private let networkService = NetworkService.shared
    
    var countries: [Country] = []
    var selectedCountry: Country?
    var defaultCountryCode: String?
    
    var onCountriesLoaded: (() -> Void)?
    var onError: ((String) -> Void)?
    var onSuccess: (() -> Void)?
    
    func loadCountries() {
        Task {
            do {
                countries = try await networkService.fetchCountries()
                await MainActor.run {
                    onCountriesLoaded?()
                }
            } catch NetworkError.invalidURL {
                await MainActor.run {
                    onError?("Invalid API URL")
                }
            } catch NetworkError.serverError(let message) {
                await MainActor.run {
                    onError?("Server error: \(message)")
                }
            } catch NetworkError.decodingError {
                await MainActor.run {
                    onError?("Failed to parse country data")
                }
            } catch {
                await MainActor.run {
                    onError?("Failed to load countries: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func loadDefaultCountry() {
        Task {
            do {
                defaultCountryCode = try await networkService.fetchUserCountry()
                await MainActor.run {
                    if let code = defaultCountryCode,
                       let country = countries.first(where: { $0.code == code }) {
                        selectedCountry = country
                        onCountriesLoaded?()
                    }
                }
            } catch NetworkError.invalidURL {
                await MainActor.run {
                    onError?("Invalid IP API URL")
                }
            } catch NetworkError.serverError(let message) {
                await MainActor.run {
                    onError?("IP API server error: \(message)")
                }
            } catch NetworkError.decodingError {
                await MainActor.run {
                    onError?("Failed to parse IP data")
                }
            } catch {
                await MainActor.run {
                    onError?("Failed to load default country: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func validateAndSignUp(email: String, password: String) {
        guard validationService.isValidEmail(email) else {
            onError?("Please enter a valid email address")
            return
        }
        
        let passwordValidation = validationService.isValidPassword(password)
        guard passwordValidation.isValid else {
            onError?(passwordValidation.message ?? "Invalid password")
            return
        }
        
        guard let country = selectedCountry else {
            onError?("Please select a country")
            return
        }
        
        do {
            try authService.signUp(email: email, password: password, country: country)
            onSuccess?()
        } catch AuthError.userAlreadyExists {
            onError?("An account with this email already exists")
        } catch {
            onError?("Failed to sign up: \(error.localizedDescription)")
        }
    }
    
    func validateAndLogin(email: String, password: String) {
        guard validationService.isValidEmail(email) else {
            onError?("Please enter a valid email address")
            return
        }
        
        do {
            try authService.login(email: email, password: password)
            onSuccess?()
        } catch AuthError.invalidCredentials {
            onError?("Invalid email or password")
        } catch {
            onError?("Failed to login: \(error.localizedDescription)")
        }
    }
    
    func logout() {
        authService.logout()
        onSuccess?()
    }
} 