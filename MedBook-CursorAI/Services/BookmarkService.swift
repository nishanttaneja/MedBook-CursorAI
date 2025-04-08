import Foundation
import CoreData

class BookmarkService {
    static let shared = BookmarkService()
    
    private init() {}
    
    private let context = CoreDataManager.shared.context
    
    func isBookmarked(bookId: String) -> Bool {
        let fetchRequest: NSFetchRequest<BookmarkedBook> = BookmarkedBook.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "bookId == %@", bookId)
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Error checking bookmark status: \(error)")
            return false
        }
    }
    
    func toggleBookmark(for book: Book) {
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
        bookmarkedBook.ratingsAverage = book.ratingsAverage ?? 0
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
        let fetchRequest: NSFetchRequest<BookmarkedBook> = BookmarkedBook.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "bookId == %@", bookId)
        
        do {
            let bookmarks = try context.fetch(fetchRequest)
            bookmarks.forEach { context.delete($0) }
            saveContext()
        } catch {
            print("Error removing bookmark: \(error)")
        }
    }
    
    func fetchBookmarkedBooks() -> [BookmarkedBook] {
        let fetchRequest: NSFetchRequest<BookmarkedBook> = BookmarkedBook.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
        
        // Filter by current user if logged in
        if let userEmail = AuthService.shared.currentUserEmail {
            let userFetchRequest: NSFetchRequest<User> = User.fetchRequest()
            userFetchRequest.predicate = NSPredicate(format: "email == %@", userEmail)
            
            do {
                if let user = try context.fetch(userFetchRequest).first {
                    fetchRequest.predicate = NSPredicate(format: "user == %@", user)
                }
            } catch {
                print("Error fetching user for bookmarks: \(error)")
            }
        }
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching bookmarked books: \(error)")
            return []
        }
    }
    
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
} 