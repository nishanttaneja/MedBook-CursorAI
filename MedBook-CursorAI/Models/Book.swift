import Foundation

struct Book: Codable, Identifiable {
    let id: String
    let title: String
    let authorName: [String]?
    let ratingsAverage: Double?
    let ratingsCount: Int?
    let coverId: Int?
    
    var coverImageURL: URL? {
        guard let coverId = coverId else { return nil }
        return URL(string: "https://covers.openlibrary.org/b/id/\(coverId)-M.jpg")
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "key"
        case title
        case authorName = "author_name"
        case ratingsAverage = "ratings_average"
        case ratingsCount = "ratings_count"
        case coverId = "cover_i"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        authorName = try container.decodeIfPresent([String].self, forKey: .authorName)
        
        // Handle ratings_average which might be a string or a number
        if let ratingString = try container.decodeIfPresent(String.self, forKey: .ratingsAverage) {
            ratingsAverage = Double(ratingString)
        } else {
            ratingsAverage = try container.decodeIfPresent(Double.self, forKey: .ratingsAverage)
        }
        
        // Handle ratings_count which might be a string or a number
        if let countString = try container.decodeIfPresent(String.self, forKey: .ratingsCount) {
            ratingsCount = Int(countString)
        } else {
            ratingsCount = try container.decodeIfPresent(Int.self, forKey: .ratingsCount)
        }
        
        coverId = try container.decodeIfPresent(Int.self, forKey: .coverId)
    }
}

struct BookSearchResponse: Codable {
    let numFound: Int
    let start: Int
    let docs: [Book]
} 