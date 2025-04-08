import Foundation

enum BookSortOption {
    case title
    case rating
    case hits
    
    var displayName: String {
        switch self {
        case .title:
            return "Sort by Title"
        case .rating:
            return "Sort by Average Rating"
        case .hits:
            return "Sort by Hits"
        }
    }
}

class BookService {
    static let shared = BookService()
    
    private init() {}
    
    func searchBooks(query: String, limit: Int = 10, offset: Int = 0) async throws -> BookSearchResponse {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://openlibrary.org/search.json?title=\(encodedQuery)&limit=\(limit)&offset=\(offset)") else {
            throw NetworkError.invalidURL
        }
        
        print("🔍 Fetching books from URL: \(url)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.serverError("Server returned status code \(httpResponse.statusCode)")
        }
        
        // Print raw response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📥 Raw API Response: \(jsonString)")
        }
        
        do {
            let searchResponse = try JSONDecoder().decode(BookSearchResponse.self, from: data)
            print("📚 Parsed \(searchResponse.docs.count) books:")
            searchResponse.docs.prefix(3).forEach { book in
                print("""
                    Book: \(book.title)
                    - Rating: \(String(describing: book.ratingsAverage))
                    - Ratings Count: \(String(describing: book.ratingsCount))
                    - Author: \(String(describing: book.authorName?.first))
                    """)
            }
            return searchResponse
        } catch {
            print("❌ Decoding error: \(error)")
            throw NetworkError.decodingError
        }
    }
    
    func sortBooks(_ books: [Book], by option: BookSortOption) -> [Book] {
        print("Sorting \(books.count) books by: \(option)")
        
        switch option {
        case .title:
            return books.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .rating:
            return books.sorted { 
                let rating1 = $0.ratingsAverage ?? 0
                let rating2 = $1.ratingsAverage ?? 0
                if rating1 == rating2 {
                    // If ratings are equal, sort by number of ratings
                    let count1 = $0.ratingsCount ?? 0
                    let count2 = $1.ratingsCount ?? 0
                    return count1 > count2
                }
                return rating1 > rating2
            }
        case .hits:
            return books.sorted {
                let hits1 = $0.ratingsCount ?? 0
                let hits2 = $1.ratingsCount ?? 0
                if hits1 == hits2 {
                    // If hits are equal, sort by rating
                    let rating1 = $0.ratingsAverage ?? 0
                    let rating2 = $1.ratingsAverage ?? 0
                    return rating1 > rating2
                }
                return hits1 > hits2
            }
        }
    }
} 