import Foundation

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
}

class NetworkService {
    static let shared = NetworkService()
    
    private init() {}
    
    func fetchCountries() async throws -> [Country] {
        guard let url = URL(string: "https://api.first.org/data/v1/countries") else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.serverError("Server returned status code \(httpResponse.statusCode)")
        }
        
        // Print the raw response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw API Response: \(jsonString)")
        }
        
        struct CountriesResponse: Codable {
            let data: [String: CountryData]
            let status: String
        }
        
        struct CountryData: Codable {
            let country: String
            let region: String?
            let region_code: String?
        }
        
        do {
            let response = try JSONDecoder().decode(CountriesResponse.self, from: data)
            return response.data.map { (code, countryData) in
                let country = Country(context: CoreDataManager.shared.context)
                country.code = code  // Use the dictionary key as the country code
                country.name = countryData.country
                return country
            }
        } catch {
            print("Decoding error: \(error)")
            throw NetworkError.decodingError
        }
    }
    
    func fetchUserCountry() async throws -> String {
        guard let url = URL(string: "http://ip-api.com/json") else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.serverError("Server returned status code \(httpResponse.statusCode)")
        }
        
        // Print the raw response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw IP API Response: \(jsonString)")
        }
        
        struct IPResponse: Codable {
            let countryCode: String
        }
        
        do {
            let response = try JSONDecoder().decode(IPResponse.self, from: data)
            return response.countryCode
        } catch {
            print("IP API Decoding error: \(error)")
            throw NetworkError.decodingError
        }
    }
} 