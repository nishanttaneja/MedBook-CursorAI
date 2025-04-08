import Foundation

class HomeViewModel {
    private let bookService = BookService.shared
    private let authService = AuthService.shared
    
    private(set) var books: [Book] = []
    private(set) var isLoading = false
    private(set) var hasMoreResults = true
    private(set) var currentOffset = 0
    private(set) var currentSortOption: BookSortOption = .title
    
    var onBooksUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoadingStateChanged: ((Bool) -> Void)?
    
    private var currentSearchQuery = ""
    private var searchTask: Task<Void, Never>?
    
    func searchBooks(query: String) {
        // Cancel any ongoing search
        searchTask?.cancel()
        
        // Only search if query is 3 or more characters
        guard query.count >= 3 else {
            books = []
            currentOffset = 0
            hasMoreResults = true
            onBooksUpdated?()
            return
        }
        
        currentSearchQuery = query
        
        // Create a new search task
        searchTask = Task {
            await performSearch(resetResults: true)
        }
    }
    
    func loadMoreBooks() {
        guard !isLoading, hasMoreResults else { return }
        
        Task {
            await performSearch(resetResults: false)
        }
    }
    
    func sortBooks(by option: BookSortOption) {
        print("\n🔄 Sorting books by: \(option)")
        currentSortOption = option
        
        // Debug print first few books before sorting
        print("\n📚 Before sorting:")
        books.prefix(3).forEach { book in
            print("""
                Title: \(book.title)
                - Rating: \(String(describing: book.ratingsAverage))
                - Hits: \(String(describing: book.ratingsCount))
                - Author: \(String(describing: book.authorName?.first))
                """)
        }
        
        books = bookService.sortBooks(books, by: option)
        
        // Debug print first few books after sorting
        print("\n📚 After sorting:")
        books.prefix(3).forEach { book in
            print("""
                Title: \(book.title)
                - Rating: \(String(describing: book.ratingsAverage))
                - Hits: \(String(describing: book.ratingsCount))
                - Author: \(String(describing: book.authorName?.first))
                """)
        }
        
        onBooksUpdated?()
    }
    
    func logout() {
        authService.logout()
    }
    
    private func performSearch(resetResults: Bool) async {
        guard !Task.isCancelled else { return }
        
        if resetResults {
            print("\n🔄 Resetting search results")
            books = []
            currentOffset = 0
            hasMoreResults = true
        }
        
        guard hasMoreResults else { return }
        
        await MainActor.run {
            isLoading = true
            onLoadingStateChanged?(true)
        }
        
        do {
            print("\n🔍 Performing search with query: '\(currentSearchQuery)'")
            print("📊 Current offset: \(currentOffset)")
            
            let response = try await bookService.searchBooks(
                query: currentSearchQuery,
                limit: 10,
                offset: currentOffset
            )
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                print("\n📚 Processing \(response.docs.count) books from response")
                if resetResults {
                    books = bookService.sortBooks(response.docs, by: currentSortOption)
                    print("🔄 Reset and sorted \(books.count) books")
                } else {
                    let newBooks = bookService.sortBooks(response.docs, by: currentSortOption)
                    books.append(contentsOf: newBooks)
                    print("➕ Added \(newBooks.count) books to existing \(books.count - newBooks.count) books")
                }
                
                currentOffset += response.docs.count
                hasMoreResults = currentOffset < response.numFound
                print("📊 Updated offset: \(currentOffset), Has more results: \(hasMoreResults)")
                
                isLoading = false
                onLoadingStateChanged?(false)
                onBooksUpdated?()
            }
        } catch {
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                print("❌ Search error: \(error.localizedDescription)")
                isLoading = false
                onLoadingStateChanged?(false)
                onError?("Failed to search books: \(error.localizedDescription)")
            }
        }
    }
} 