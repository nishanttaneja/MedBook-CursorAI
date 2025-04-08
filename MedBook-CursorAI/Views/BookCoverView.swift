import SwiftUI

struct BookCoverView: View {
    let coverId: Int?
    let title: String
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var loadError = false
    
    private let imageCache = ImageCacheService.shared
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if loadError {
                Text("!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.red.opacity(0.2))
            } else {
                Text(title.prefix(1))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.2))
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let coverId = coverId else {
            isLoading = false
            return
        }
        
        let urlString = "https://covers.openlibrary.org/b/id/\(coverId)-L.jpg"
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        // Check cache first
        if let cachedImage = imageCache.image(for: url) {
            self.image = cachedImage
            self.isLoading = false
            return
        }
        
        // If not in cache, load from network
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error loading image: \(error.localizedDescription)")
                    self.loadError = true
                    self.isLoading = false
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("❌ Invalid response when loading image")
                    self.loadError = true
                    self.isLoading = false
                    return
                }
                
                if let data = data, let downloadedImage = UIImage(data: data) {
                    self.image = downloadedImage
                    // Cache the downloaded image
                    self.imageCache.cache(image: downloadedImage, for: url)
                    self.loadError = false
                } else {
                    print("❌ Failed to create image from data")
                    self.loadError = true
                }
                self.isLoading = false
            }
        }
        task.resume()
    }
} 