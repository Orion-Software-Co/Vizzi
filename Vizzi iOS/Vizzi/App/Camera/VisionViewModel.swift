//
//  ImageViewModel.swift
//  BabelPod
//
//  Created by Adrian Martushev on 10/19/24.
//

import SwiftUI
import OpenAI
import FirebaseStorage


struct MenuModel : Identifiable {
    var id : String
    var sourceURL : String
    var menuItems : [MenuItem]
}

struct MenuItem : Hashable {
    var itemName: String
    var price: String
    var translatedItemName: String
    var type: String
}

class VisionViewModel : ObservableObject {
    
    @Published var showErrorMessage : Bool = false
    @Published var errorMessage : String = ""
    @Published var isAnalyzingImage = false
    @Published var selectedImage: Image?
    @Published var sourceURL : String?
    @Published var menuItems : [MenuItem] = []
    @Published var imageAnalysisResult: String = ""
    
    let openAI = OpenAI(apiToken: "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")
        
    
    // MARK: Landmark Identification
    func uploadImageToFirebaseStorage(image : UIImage, completion: @escaping (String?) -> Void) {

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            displayError("Failed to encode image.")
            completion(nil)
            return
        }

        let storageRef = Storage.storage().reference().child("vision_images/\(UUID().uuidString).jpg")

        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                self.displayError("Failed to upload image: \(error.localizedDescription)")
                completion(nil)
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    self.displayError("Failed to get download URL: \(error.localizedDescription)")
                    completion(nil)
                } else if let downloadURL = url {
                    self.sourceURL = downloadURL.absoluteString
                    completion(downloadURL.absoluteString)
                }
            }
        }
    }
    
    func captureImageAndDescribe(image: UIImage, targetLocale : String, openAIVM: OpenAIViewModel) {
        isAnalyzingImage = true
        
        uploadImageToFirebaseStorage(image: image) { downloadURL in
            guard let downloadURL = downloadURL else {
                self.displayError("Failed to upload image.")
                return
            }

            guard let url = URL(string: "https://vizzi-dev-c44e4e36a54d.herokuapp.com/analyze_image") else {
                self.displayError("Invalid server URL.")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let requestBody: [String: String] = ["image_url": downloadURL, "target_lang" : targetLocale]
            print("Request body: \(requestBody)")
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
                request.httpBody = jsonData
            } catch {
                self.displayError("Failed to create JSON body: \(error.localizedDescription)")
                return
            }

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    self.displayError("Failed to send request: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    self.displayError("No data received from server.")
                    return
                }
                
                do {
                    // Print the raw response for debugging
                    if let dataString = String(data: data, encoding: .utf8) {
                        print("Raw response from server: \(dataString)")
                    }

                    // Attempt to parse the JSON
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let result = json["result"] as? [String: Any],  // result is a dictionary
                       let textArray = result["text"] as? [String] {  // Extract the text array
                        DispatchQueue.main.async {
                            let combinedText = textArray.joined(separator: "\n")  // Join text elements into a single string
                            print("Response: \(combinedText)")  // Now this should print
                            self.imageAnalysisResult = combinedText  // Store properly formatted text
                            self.isAnalyzingImage = false
                        }
                    } else {
                        self.displayError("Invalid response format: Missing 'result' key or incorrect type.")
                    }
                } catch {
                    self.displayError("Failed to parse response: \(error.localizedDescription)")
                }
                
            }.resume()
        }
    }
    
    func fetchLandmarkDetails(landmark : String, location : String) {
        self.isAnalyzingImage = false

    }
        
    // Helper function to display errors
    private func displayError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showErrorMessage = true
            self.isAnalyzingImage = false
        }
    }
    
    func parseMenuItems(response: [[String: Any]]) -> [MenuItem] {
        var menuItems = [MenuItem]()

        for item in response {
            let itemName = item["itemName"] as? String ?? "Unknown Item"
            let price = item["price"] as? String ?? "N/A"
            let translatedItemName = item["translatedItemName"] as? String ?? "No Translation"
            let type = item["type"] as? String ?? "Unknown Type"

            let menuItem = MenuItem(itemName: itemName, price: price, translatedItemName: translatedItemName, type: type)
            menuItems.append(menuItem)
        }

        print(menuItems)
        return menuItems
    }
}
