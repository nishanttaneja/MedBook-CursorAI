import UIKit

class BookTableViewCell: UITableViewCell {
    static let identifier = "BookTableViewCell"
    
    private let bookImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemOrange
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let hitsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(bookImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(authorLabel)
        contentView.addSubview(ratingLabel)
        contentView.addSubview(hitsLabel)
        
        NSLayoutConstraint.activate([
            bookImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bookImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            bookImageView.widthAnchor.constraint(equalToConstant: 60),
            bookImageView.heightAnchor.constraint(equalToConstant: 90),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: bookImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            authorLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            authorLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            authorLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            ratingLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 4),
            ratingLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            
            hitsLabel.centerYAnchor.constraint(equalTo: ratingLabel.centerYAnchor),
            hitsLabel.leadingAnchor.constraint(equalTo: ratingLabel.trailingAnchor, constant: 8),
            hitsLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bookImageView.image = nil
        titleLabel.text = nil
        authorLabel.text = nil
        ratingLabel.text = nil
        hitsLabel.text = nil
    }
    
    func configure(with book: Book) {
        titleLabel.text = book.title
        authorLabel.text = book.authorName?.first ?? "Unknown Author"
        
        // Debug print for ratings
        print("""
            📖 Configuring cell for book:
            Title: \(book.title)
            Author: \(book.authorName?.first ?? "Unknown")
            Rating: \(String(describing: book.ratingsAverage))
            Hits: \(String(describing: book.ratingsCount))
            """)
        
        if let rating = book.ratingsAverage {
            ratingLabel.text = String(format: "★ %.1f", rating)
            ratingLabel.textColor = .systemOrange
        } else {
            ratingLabel.text = "★ No rating"
            ratingLabel.textColor = .systemGray
        }
        
        if let hits = book.ratingsCount {
            hitsLabel.text = "(\(hits) ratings)"
            hitsLabel.textColor = .secondaryLabel
        } else {
            hitsLabel.text = "(No ratings)"
            hitsLabel.textColor = .systemGray
        }
        
        if let imageURL = book.coverImageURL {
            URLSession.shared.dataTask(with: imageURL) { [weak self] data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.bookImageView.image = image
                    }
                }
            }.resume()
        }
    }
} 