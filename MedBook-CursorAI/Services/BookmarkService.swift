import Foundation
import CoreData

class BookmarkService {
    static let shared = BookmarkService()
    
    private let context: NSManagedObjectContext
    private var cachedBookmarkedBooks: [BookmarkedBook]?
    private var lastFetchTime: Date?
    private let cacheValidityDuration: TimeInterval = 30 // Cache validity in seconds
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.context) {
        self.context = context
    }
    
    func isBookmarked(bookId: String) -> Bool {
        // First check cache
        if let cachedBooks = cachedBookmarkedBooks {
            return cachedBooks.contains { $0.bookId == bookId }
        }
        
        // If no cache, query Core Data
        let request: NSFetchRequest<BookmarkedBook> = BookmarkedBook.fetchRequest()
        request.predicate = NSPredicate(format: "bookId == %@", bookId)
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("❌ Failed to check bookmark status: \(error)")
            return false
        }
    }
    
    func toggleBookmark(for book: Book) {
        // Invalidate cache when modifying bookmarks
        cachedBookmarkedBooks = nil
        lastFetchTime = nil
        
        if isBookmarked(bookId: book.id) {
            removeBookmark(bookId: book.id)
        } else {
            addBookmark(book)
        }
    }
    
    private func addBookmark(_ book: Book) {
        let bookmarkedBook = BookmarkedBook(context: context)
        bookmarkedBook.bookId = book.id
        bookmarkedBook.title = book.title
        bookmarkedBook.authorName = book.authorName?.first
        bookmarkedBook.ratingsAverage = book.ratingsAverage ?? 0.0
        bookmarkedBook.ratingsCount = Int32(book.ratingsCount ?? 0)
        bookmarkedBook.coverId = Int32(book.coverId ?? 0)
        bookmarkedBook.dateAdded = Date()
        
        // Associate with current user if logged in
        if let userEmail = AuthService.shared.currentUserEmail {
            let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "email == %@", userEmail)
            
            do {
                if let user = try context.fetch(fetchRequest).first {
                    bookmarkedBook.user = user
                }
            } catch {
                print("Error associating bookmark with user: \(error)")
            }
        }
        
        saveContext()
    }
    
    private func removeBookmark(bookId: String) {
        let request: NSFetchRequest<BookmarkedBook> = BookmarkedBook.fetchRequest()
        request.predicate = NSPredicate(format: "bookId == %@", bookId)
        
        do {
            let books = try context.fetch(request)
            books.forEach(context.delete)
            saveContext()
        } catch {
            print("❌ Failed to remove bookmark: \(error)")
        }
    }
    
    func fetchBookmarkedBooks() -> [BookmarkedBook] {
        // Check if we have valid cached data
        if let cachedBooks = cachedBookmarkedBooks,
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheValidityDuration {
            print("📚 Using cached bookmarked books")
            return cachedBooks
        }
        
        print("📚 Fetching bookmarked books from Core Data")
        let request: NSFetchRequest<BookmarkedBook> = BookmarkedBook.fetchRequest()
        
        do {
            let books = try context.fetch(request)
            // Update cache
            self.cachedBookmarkedBooks = books
            self.lastFetchTime = Date()
            return books
        } catch {
            print("❌ Failed to fetch bookmarked books: \(error)")
            return []
        }
    }
    
    private func saveContext() {
        if context.hasChanges {
            CoreDataManager.shared.saveContext()
        }
    }
} 