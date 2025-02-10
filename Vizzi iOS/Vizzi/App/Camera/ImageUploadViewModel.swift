

import SwiftUI
import Firebase
import FirebaseStorage
import AVFoundation
import CoreLocation

class ImageUploadViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var videoURL: URL?
    @Published var locationString: String = "Fetching location..."
    
    private var locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var userLatitude: Double = 0.0
    private var userLongitude: Double = 0.0
    private var isFetchingLocation = false
    private var locationCompletion: ((Bool) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    /// Uploads video and saves post to Firestore
    func uploadVideo(description: String, isPublic: Bool, userID: String, completion: @escaping (Bool, String?) -> Void) {
        guard let localVideoURL = videoURL else {
            completion(false, "No video to upload")
            return
        }
        
        if locationString == "Fetching location..." || isFetchingLocation {
            print("🔄 Waiting for location before uploading...")
            fetchLocation { success in
                if success {
                    self.uploadVideo(description: description, isPublic: isPublic, userID: userID, completion: completion)
                } else {
                    print("⚠️ Location fetch failed, proceeding without location name.")
                    DispatchQueue.main.async {
                        self.locationString = "Unknown Location"
                    }
                    self.uploadVideo(description: description, isPublic: isPublic, userID: userID, completion: completion)
                }
            }
            return
        }
        
        let videoID = UUID().uuidString
        let storageRef = Storage.storage().reference().child("videos/\(videoID).mov")
        
        // Upload video to Firebase Storage
        storageRef.putFile(from: localVideoURL, metadata: nil) { (_, error) in
            if let error = error {
                completion(false, "Upload failed: \(error.localizedDescription)")
                return
            }
            
            // Get the download URL
            storageRef.downloadURL { url, error in
                guard let downloadURL = url?.absoluteString else {
                    completion(false, "Failed to get video download URL")
                    return
                }
                
                // Generate & upload thumbnail
                self.generateThumbnail(for: localVideoURL) { thumbnailURL in
                    guard let thumbnailURL = thumbnailURL else {
                        completion(false, "Failed to upload thumbnail")
                        return
                    }
                    
                    // Prepare post data
                    let postData: [String: Any] = [
                        "id": videoID,
                        "videoURL": downloadURL,
                        "thumbnailURL": thumbnailURL,
                        "locationStr": self.locationString,
                        "lat": self.userLatitude,
                        "lng": self.userLongitude,
                        "description": description,
                        "uploadedBy": userID,
                        "dateUploaded": Timestamp(date: Date())
                    ]
                    
                    // Save to Firestore
                    Firestore.firestore().collection("posts").document(videoID).setData(postData) { error in
                        if let error = error {
                            completion(false, "Failed to save post: \(error.localizedDescription)")
                        } else {
                            completion(true, nil)
                        }
                    }
                }
            }
        }
    }
    
    /// Fetches user location and performs reverse geocoding
    private func fetchLocation(completion: @escaping (Bool) -> Void) {
        isFetchingLocation = true
        locationCompletion = completion
        locationManager.requestLocation() // Fetch latest location
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) { // Timeout after 3 sec
            DispatchQueue.main.async {
                if self.locationString == "Fetching location..." {
                    self.locationString = "Unknown Location"
                    completion(false)
                }
            }
        }
    }
    
    /// Updates location variables when location changes
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        userLatitude = location.coordinate.latitude
        userLongitude = location.coordinate.longitude
        print("📍 Location updated: \(userLatitude), \(userLongitude)")
        
        // Reverse Geocode to get location name
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("⚠️ Reverse geocoding failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.locationString = "Unknown Location"
                    self.isFetchingLocation = false
                }
                self.locationCompletion?(false)
                return
            }
            
            if let placemark = placemarks?.first {
                var locationComponents: [String] = []
                
                if let venue = placemark.name { locationComponents.append(venue) } // Street or venue
                if let city = placemark.locality { locationComponents.append(city) } // City
                if let state = placemark.administrativeArea { locationComponents.append(state) } // State
                if let country = placemark.country { locationComponents.append(country) } // Country
                
                DispatchQueue.main.async {
                    self.locationString = locationComponents.joined(separator: ", ")
                    print("📌 Resolved Location: \(self.locationString)")
                    self.isFetchingLocation = false
                }
                self.locationCompletion?(true)
            } else {
                DispatchQueue.main.async {
                    self.locationString = "Unknown Location"
                    self.isFetchingLocation = false
                }
                self.locationCompletion?(false)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Failed to find user's location: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.locationString = "Unknown Location"
            self.isFetchingLocation = false
        }
        locationCompletion?(false)
    }
    
    /// Generates a thumbnail from the video and uploads it to Firebase Storage
    private func generateThumbnail(for videoURL: URL, completion: @escaping (String?) -> Void) {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let timestamp = CMTime(seconds: 1, preferredTimescale: 60) // Extract thumbnail at 1 second
        DispatchQueue.global().async {
            do {
                let cgImage = try imageGenerator.copyCGImage(at: timestamp, actualTime: nil)
                let uiImage = UIImage(cgImage: cgImage)
                
                // Convert UIImage to Data
                guard let imageData = uiImage.jpegData(compressionQuality: 0.8) else {
                    completion(nil)
                    return
                }
                
                // Upload to Firebase Storage
                let thumbnailID = UUID().uuidString
                let storageRef = Storage.storage().reference().child("thumbnails/\(thumbnailID).jpg")
                
                storageRef.putData(imageData, metadata: nil) { (_, error) in
                    if let error = error {
                        print("Failed to upload thumbnail: \(error.localizedDescription)")
                        completion(nil)
                        return
                    }
                    
                    // Get thumbnail download URL
                    storageRef.downloadURL { url, error in
                        guard let downloadURL = url?.absoluteString else {
                            completion(nil)
                            return
                        }
                        completion(downloadURL)
                    }
                }
            } catch {
                print("Failed to generate thumbnail: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
}
