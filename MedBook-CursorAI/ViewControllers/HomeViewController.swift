import UIKit

class HomeViewController: BaseViewController {
    private let viewModel = HomeViewModel()
    
    private let searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchBar.placeholder = "Search books..."
        return controller
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(BookTableViewCell.self, forCellReuseIdentifier: BookTableViewCell.identifier)
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 100
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "No books found"
        label.textAlignment = .center
        label.textColor = .gray
        label.isHidden = true
        return label
    }()
    
    private lazy var bookmarksButton = UIBarButtonItem(
        image: UIImage(systemName: "bookmark"),
        style: .plain,
        target: nil,
        action: nil
    )
    
    private lazy var sortButton = UIBarButtonItem(
        image: UIImage(systemName: "arrow.up.arrow.down"),
        style: .plain,
        target: nil,
        action: nil
    )
    
    override func setupUI() {
        super.setupUI()
        title = "MedBook"
        
        // Configure button targets
        bookmarksButton.target = self
        bookmarksButton.action = #selector(toggleBookmarks)
        sortButton.target = self
        sortButton.action = #selector(showSortOptions)
        
        // Add logout button
        let logoutButton = UIBarButtonItem(
            title: "Logout",
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )
        navigationItem.rightBarButtonItems = [logoutButton, sortButton, bookmarksButton]
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
        searchController.searchBar.delegate = self
        
        setupViewModel()
    }
    
    private func setupViewModel() {
        viewModel.onBooksUpdated = { [weak self] in
            self?.tableView.reloadData()
            self?.updateEmptyState()
            // Update bookmark button state
            self?.bookmarksButton.image = self?.viewModel.isShowingBookmarks == true ? 
                UIImage(systemName: "bookmark.fill") : 
                UIImage(systemName: "bookmark")
        }
        
        viewModel.onError = { [weak self] message in
            self?.showAlert(title: "Error", message: message)
        }
        
        viewModel.onLoadingStateChanged = { [weak self] isLoading in
            if isLoading {
                self?.activityIndicator.startAnimating()
            } else {
                self?.activityIndicator.stopAnimating()
            }
        }
    }
    
    private func updateEmptyState() {
        emptyStateLabel.isHidden = !viewModel.books.isEmpty
        emptyStateLabel.text = viewModel.isShowingBookmarks ? "No bookmarks found" : "No books found"
    }
    
    @objc private func logoutTapped() {
        let alert = UIAlertController(
            title: "Logout",
            message: "Are you sure you want to logout?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { [weak self] _ in
            self?.viewModel.logout()
            let landingVC = LandingViewController()
            self?.navigationController?.setViewControllers([landingVC], animated: true)
        })
        
        present(alert, animated: true)
    }
    
    @objc private func toggleBookmarks() {
        if viewModel.isShowingBookmarks {
            // Reset to showing all books
            searchController.searchBar.text = ""
            viewModel.resetToAllBooks()
        } else {
            // Show bookmarks
            viewModel.showBookmarks()
        }
    }
    
    @objc private func showSortOptions() {
        let alert = UIAlertController(title: "Sort Books", message: nil, preferredStyle: .actionSheet)
        
        let sortOptions: [(String, BookSortOption)] = [
            ("Title", .title),
            ("Rating", .rating),
            ("Hits", .hits)
        ]
        
        for (title, option) in sortOptions {
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.viewModel.sortBooks(by: option)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.books.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BookTableViewCell.identifier, for: indexPath) as? BookTableViewCell else {
            return UITableViewCell()
        }
        
        let book = viewModel.books[indexPath.row]
        let isBookmarked = viewModel.isBookmarked(bookId: book.id)
        cell.configure(with: book, isBookmarked: isBookmarked)
        cell.onBookmarkTapped = { [weak self] in
            // Add haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // Animate the button
            UIView.animate(withDuration: 0.2, animations: {
                cell.bookmarkButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }) { _ in
                UIView.animate(withDuration: 0.2) {
                    cell.bookmarkButton.transform = .identity
                }
            }
            
            self?.viewModel.toggleBookmark(for: book)
            // Update cell's bookmark state immediately
            cell.bookmarkButton.isSelected = !isBookmarked
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == viewModel.books.count - 1 {
            viewModel.loadMoreBooks()
        }
    }
}

extension HomeViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchBooks(query: searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Clear the search text
        searchBar.text = ""
        
        // If showing bookmarks, reload all bookmarks
        if viewModel.isShowingBookmarks {
            viewModel.showBookmarks()
        } else {
            // Otherwise, reset to default search
            viewModel.searchBooks(query: "")
        }
    }
}

extension BookSortOption: CaseIterable {
    static var allCases: [BookSortOption] = [.title, .rating, .hits]
} 