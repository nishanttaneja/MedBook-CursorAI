import UIKit

class ImageCacheService {
    static let shared = ImageCacheService()
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Set up cache limits
        cache.countLimit = 100 // Maximum number of images to keep in memory
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB limit
        
        // Set up disk cache directory
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache")
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        print("📸 Initialized image cache service")
    }
    
    func image(for url: URL) -> UIImage? {
        let key = url.absoluteString as NSString
        
        // Check memory cache first
        if let cachedImage = cache.object(forKey: key) {
            print("📸 Retrieved image from memory cache: \(url.lastPathComponent)")
            return cachedImage
        }
        
        // Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent(url.lastPathComponent)
        if let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            // Store in memory cache for future use
            cache.setObject(image, forKey: key)
            print("📸 Retrieved image from disk cache: \(url.lastPathComponent)")
            return image
        }
        
        return nil
    }
    
    func cache(image: UIImage, for url: URL) {
        let key = url.absoluteString as NSString
        
        // Store in memory cache
        cache.setObject(image, forKey: key)
        
        // Store in disk cache
        let fileURL = cacheDirectory.appendingPathComponent(url.lastPathComponent)
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: fileURL)
            print("📸 Cached image: \(url.lastPathComponent)")
        }
    }
    
    func clearCache() {
        // Clear memory cache
        cache.removeAllObjects()
        
        // Clear disk cache
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        print("🧹 Cleared image cache")
    }
} 