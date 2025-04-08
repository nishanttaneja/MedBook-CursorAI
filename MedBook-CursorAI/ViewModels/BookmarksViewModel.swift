import Foundation

class BookmarksViewModel {
    var bookmarkedBooks: [Book] = []
    var isLoading = false
    var error: Error?
    
    private let bookmarkService: BookmarkService
    
    var onBooksUpdated: (() -> Void)?
    var onLoadingStateChanged: ((Bool) -> Void)?
    var onError: ((Error) -> Void)?
    
    init(bookmarkService: BookmarkService = .shared) {
        self.bookmarkService = bookmarkService
    }
    
    func loadBookmarkedBooks() {
        isLoading = true
        onLoadingStateChanged?(true)
        error = nil
        
        // Fetch bookmarked books from Core Data
        let fetchedBooks = bookmarkService.fetchBookmarkedBooks()
        
        // Convert BookmarkedBook entities to Book models
        self.bookmarkedBooks = fetchedBooks.compactMap { bookmarkedBook -> Book? in
            guard let bookId = bookmarkedBook.bookId,
                  let title = bookmarkedBook.title else {
                return nil
            }
            
            // Create a dictionary that matches the Book's CodingKeys
            let bookDict: [String: Any] = [
                "key": bookId,
                "title": title,
                "author_name": bookmarkedBook.authorName.map { [$0] } as Any,
                "ratings_average": bookmarkedBook.ratingsAverage as Any,
                "ratings_count": bookmarkedBook.ratingsCount as Any,
                "cover_i": bookmarkedBook.coverId as Any
            ]
            
            // Convert dictionary to JSON data
            guard let jsonData = try? JSONSerialization.data(withJSONObject: bookDict) else {
                return nil
            }
            
            // Decode the JSON data into a Book
            return try? JSONDecoder().decode(Book.self, from: jsonData)
        }
        
        isLoading = false
        onLoadingStateChanged?(false)
        onBooksUpdated?()
    }
    
    func removeBookmark(for book: Book) {
        bookmarkService.toggleBookmark(for: book)
        loadBookmarkedBooks() // Reload the list
    }
    
    func isBookmarked(bookId: String) -> Bool {
        return bookmarkService.isBookmarked(bookId: bookId)
    }
} 