import Foundation

class HomeViewModel {
    private let bookService = BookService.shared
    private let authService = AuthService.shared
    private let bookmarkService = BookmarkService.shared
    
    private(set) var books: [Book] = []
    private(set) var isLoading = false
    private(set) var hasMoreResults = true
    private(set) var currentOffset = 0
    private(set) var currentSortOption: BookSortOption = .title
    private(set) var isShowingBookmarks = false
    
    var onBooksUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoadingStateChanged: ((Bool) -> Void)?
    
    private var currentSearchQuery = ""
    private var searchTask: Task<Void, Never>?
    private var retryCount = 0
    private let maxRetries = 2
    
    init() {
        // Load initial books
        searchBooks(query: "")
    }
    
    func searchBooks(query: String) {
        // Cancel any ongoing search
        searchTask?.cancel()
        
        // Store the current search query
        currentSearchQuery = query
        
        // If we're showing bookmarks, filter locally
        if isShowingBookmarks {
            print("\n🔍 Filtering bookmarked books with query: '\(query)'")
            
            // If query is empty, show all bookmarks
            if query.isEmpty {
                showBookmarks()
                return
            }
            
            // Filter the current books array based on the query
            let filteredBooks = books.filter { book in
                let titleMatch = book.title.localizedCaseInsensitiveContains(query)
                let authorMatch = book.authorName?.contains { $0.localizedCaseInsensitiveContains(query) } ?? false
                return titleMatch || authorMatch
            }
            
            // Update the books array with filtered results
            books = filteredBooks
            
            // Sort the filtered results
            if !books.isEmpty {
                books = bookService.sortBooks(books, by: currentSortOption)
                print("📚 Filtered and sorted \(books.count) bookmarked books")
            } else {
                print("📚 No bookmarked books match the query")
            }
            
            onBooksUpdated?()
            return
        }
        
        // For empty queries, use a default search term for initial load
        let searchQuery = query.isEmpty ? "medicine" : query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Only validate length for non-empty user queries
        if !query.isEmpty && searchQuery.count < 3 {
            books = []
            currentOffset = 0
            hasMoreResults = true
            isShowingBookmarks = false
            onBooksUpdated?()
            return
        }
        
        isShowingBookmarks = false
        
        // Create a new search task
        searchTask = Task {
            await performSearch(resetResults: true)
        }
    }
    
    func loadMoreBooks() {
        guard !isLoading, hasMoreResults, !isShowingBookmarks else { return }
        
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
    
    func showBookmarks() {
        print("\n📚 Showing bookmarks")
        isLoading = true
        onLoadingStateChanged?(true)
        
        // Fetch bookmarked books from Core Data
        let fetchedBooks = bookmarkService.fetchBookmarkedBooks()
        print("📚 Fetched \(fetchedBooks.count) bookmarked books")
        
        // Convert BookmarkedBook entities to Book models - optimized version
        let convertedBooks = fetchedBooks.compactMap { bookmarkedBook -> Book? in
            guard let bookId = bookmarkedBook.bookId,
                  let title = bookmarkedBook.title else {
                print("❌ Failed to convert bookmarked book: missing required fields")
                return nil
            }
            
            // Create a Book directly instead of using JSON serialization/deserialization
            let book = Book(
                id: bookId,
                title: title,
                authorName: bookmarkedBook.authorName.map { [$0] } ?? [],
                ratingsAverage: bookmarkedBook.ratingsAverage,
                ratingsCount: Int(bookmarkedBook.ratingsCount),
                coverId: Int(bookmarkedBook.coverId)
            )
            
            print("✅ Successfully converted book: \(book.title)")
            return book
        }
        
        // Update the books array with the converted books
        self.books = convertedBooks
        
        // Only sort if we have books
        if !books.isEmpty {
            books = bookService.sortBooks(books, by: currentSortOption)
            print("📚 Sorted \(books.count) bookmarked books")
        } else {
            print("📚 No bookmarked books to sort")
        }
        
        isShowingBookmarks = true
        isLoading = false
        onLoadingStateChanged?(false)
        onBooksUpdated?()
    }
    
    func toggleBookmark(for book: Book) {
        print("\n🔖 Toggling bookmark for book: \(book.title)")
        bookmarkService.toggleBookmark(for: book)
        
        // If we're showing bookmarks, refresh the list
        if isShowingBookmarks {
            // Store the current search query
            let queryToReapply = currentSearchQuery
            
            // If there's an active search, we need to handle this differently
            if !queryToReapply.isEmpty {
                print("🔍 Active search detected: '\(queryToReapply)'")
                
                // If we're removing a bookmark (the book is no longer bookmarked)
                if !bookmarkService.isBookmarked(bookId: book.id) {
                    print("🗑️ Removing book from search results: \(book.title)")
                    
                    // Simply remove this book from the current filtered results
                    books.removeAll { $0.id == book.id }
                    print("📚 Remaining books in search results: \(books.count)")
                    
                    // Update the UI
                    onBooksUpdated?()
                    return
                }
            }
            
            // For all other cases (adding a bookmark or no active search),
            // fetch fresh bookmarked books from Core Data
            let fetchedBooks = bookmarkService.fetchBookmarkedBooks()
            print("📚 Fetched \(fetchedBooks.count) bookmarked books after toggle")
            
            // Convert BookmarkedBook entities to Book models - optimized version
            let convertedBooks = fetchedBooks.compactMap { bookmarkedBook -> Book? in
                guard let bookId = bookmarkedBook.bookId,
                      let title = bookmarkedBook.title else {
                    print("❌ Failed to convert bookmarked book: missing required fields")
                    return nil
                }
                
                // Create a Book directly instead of using JSON serialization/deserialization
                let book = Book(
                    id: bookId,
                    title: title,
                    authorName: bookmarkedBook.authorName.map { [$0] } ?? [],
                    ratingsAverage: bookmarkedBook.ratingsAverage,
                    ratingsCount: Int(bookmarkedBook.ratingsCount),
                    coverId: Int(bookmarkedBook.coverId)
                )
                
                print("✅ Successfully converted book: \(book.title)")
                return book
            }
            
            // Update the books array with the converted books
            self.books = convertedBooks
            
            // Sort the books
            if !books.isEmpty {
                books = bookService.sortBooks(books, by: currentSortOption)
                print("📚 Sorted \(books.count) bookmarked books")
            } else {
                print("📚 No bookmarked books to sort")
            }
            
            // If there was an active search, apply the filter
            if !queryToReapply.isEmpty {
                print("🔄 Applying search filter: '\(queryToReapply)'")
                let filteredBooks = books.filter { book in
                    let titleMatch = book.title.localizedCaseInsensitiveContains(queryToReapply)
                    let authorMatch = book.authorName?.contains { $0.localizedCaseInsensitiveContains(queryToReapply) } ?? false
                    return titleMatch || authorMatch
                }
                
                books = filteredBooks
                print("📚 Filtered to \(books.count) bookmarked books matching query")
            }
            
            // Update the UI
            onBooksUpdated?()
        }
    }
    
    func isBookmarked(bookId: String) -> Bool {
        return bookmarkService.isBookmarked(bookId: bookId)
    }
    
    func logout() {
        authService.logout()
    }
    
    // Helper method to reset to showing all books
    func resetToAllBooks() {
        print("\n🔄 Resetting to show all books")
        isShowingBookmarks = false
        searchBooks(query: "")
    }
    
    private func performSearch(resetResults: Bool) async {
        guard !Task.isCancelled else { return }
        
        if resetResults {
            print("\n🔄 Resetting search results")
            books = []
            currentOffset = 0
            hasMoreResults = true
            retryCount = 0
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
            
            guard !Task.isCancelled else { 
                print("⚠️ Search task was cancelled after receiving response")
                return 
            }
            
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
            print("❌ Search error: \(error)")
            
            // Check if the error is due to task cancellation
            if (error as NSError).domain == NSURLErrorDomain && 
               (error as NSError).code == NSURLErrorCancelled {
                print("⚠️ Search was cancelled by user")
                await MainActor.run {
                    isLoading = false
                    onLoadingStateChanged?(false)
                }
                return
            }
            
            // Handle NetworkError cases with more descriptive messages
            var errorMessage: String
            var shouldRetry = false
            
            if let networkError = error as? NetworkError {
                switch networkError {
                case .invalidURL:
                    errorMessage = "Invalid search URL"
                case .noData:
                    errorMessage = "No data received from server"
                case .decodingError:
                    errorMessage = "Failed to parse search results"
                case .serverError(let message):
                    if message.contains("status code 500") {
                        errorMessage = "The Open Library service is temporarily unavailable"
                        shouldRetry = true
                    } else if message.contains("status code 429") {
                        errorMessage = "Too many requests. Please try again later"
                    } else if message.contains("status code 404") {
                        errorMessage = "No books found matching your search"
                    } else {
                        errorMessage = "Server error: \(message)"
                        shouldRetry = message.contains("status code 5")
                    }
                }
            } else {
                errorMessage = "Failed to search books: \(error.localizedDescription)"
            }
            
            // Retry logic for server errors
            if shouldRetry && retryCount < maxRetries {
                retryCount += 1
                print("🔄 Retrying search (attempt \(retryCount)/\(maxRetries))")
                
                // Add a small delay before retrying
                try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 * Double(retryCount)))
                
                // Check if the task is still valid before retrying
                guard !Task.isCancelled else {
                    print("⚠️ Search task was cancelled before retry")
                    await MainActor.run {
                        isLoading = false
                        onLoadingStateChanged?(false)
                    }
                    return
                }
                
                // Create a new task for the retry to avoid recursion issues
                let retryTask = Task {
                    await performSearch(resetResults: false)
                }
                
                // Wait for the retry task to complete
                await retryTask.value
                return
            } else if shouldRetry {
                // We've reached max retries but still want to retry
                print("⚠️ Maximum retry attempts reached (\(maxRetries))")
                errorMessage = "The Open Library service is temporarily unavailable. Please try again later."
            }
            
            // Only show error if we don't have any books yet
            if books.isEmpty {
                await MainActor.run {
                    isLoading = false
                    onLoadingStateChanged?(false)
                    onError?(errorMessage)
                }
            } else {
                // If we already have books, just log the error but don't show it to the user
                print("⚠️ Search error occurred but books are already loaded: \(errorMessage)")
                await MainActor.run {
                    isLoading = false
                    onLoadingStateChanged?(false)
                }
            }
        }
    }
} 
