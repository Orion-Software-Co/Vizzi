
import Foundation
import UIKit
import SwiftUI
import Combine

class ImageCache {
    static let shared = NSCache<NSString, UIImage>()

    static func getImage(forKey key: String) -> UIImage? {
        return shared.object(forKey: key as NSString)
    }

    static func setImage(_ image: UIImage, forKey key: String) {
        shared.setObject(image, forKey: key as NSString)
    }
}

class CachedImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var urlString: String
    private var cancellable: AnyCancellable?

    init(urlString: String) {
        self.urlString = urlString
    }

    func load() {
        if let cachedImage = ImageCache.getImage(forKey: urlString) {
            image = cachedImage
            return
        }

        guard let url = URL(string: urlString) else {
            return
        }

        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                if let image = $0 {
                    ImageCache.setImage(image, forKey: self?.urlString ?? "")
                    self?.image = image
                }
            }
    }

    func cancel() {
        cancellable?.cancel()
    }
}

struct CachedAsyncImageView: View {
    @StateObject private var loader: CachedImageLoader
    init(urlString: String) {
        _loader = StateObject(wrappedValue: CachedImageLoader(urlString: urlString))
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
            } else {
                ProgressView()
            }
        }
        .onAppear(perform: loader.load)
        .onDisappear(perform: loader.cancel)
    }
}



struct ProfilePhotoOrInitials : View {
    
    let user : User
    let radius : CGFloat
    let fontSize : CGFloat
    
    var cornerRadius : CGFloat = 100
    
    var body: some View {

        if ( user.profilePhoto.isEmpty ) {
            
            if user.name != "" && user.name != " " {
                Text(getInitials(fullName: user.name))
                    .font(.system(size: fontSize))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.onyx)
                    .frame(width: radius, height: radius)
                    .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .cornerRadius(cornerRadius)
                
            } else {
                Image("default_profile")
                    .resizable()
                    .scaledToFit()
                    .frame(width: radius, height: radius)
                    .cornerRadius(cornerRadius)
            }
            
        } else {
            CachedAsyncImageView(urlString: user.profilePhoto)
                .scaledToFill()
                .frame(width: radius, height: radius)
                .cornerRadius(cornerRadius)
        }
    }
}


func getInitials(fullName : String) -> String {
    let names = fullName.split(separator: " ")

    switch names.count {
    case 0:
        return ""
    case 1:
        // Only one name provided
        return String(names.first!.prefix(1))
    default:
        // Two or more names provided, get the first and last name initials
        let firstInitial = names.first!.prefix(1)
        let lastInitial = names.last!.prefix(1)
        return "\(firstInitial)\(lastInitial)"
    }
}
