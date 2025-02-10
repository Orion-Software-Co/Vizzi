
import SwiftUI
import Foundation
import FirebaseFirestore
import CoreLocation
@preconcurrency import MapKit
import Geohash
import Contacts


class MapViewModel : NSObject, ObservableObject, CLLocationManagerDelegate, @unchecked Sendable {
    
    private var locationManager = CLLocationManager()
    @Published var userLocation: CLLocation?
    @Published var userLocationGeoHash : String = ""
    @Published var locationString = ""
    
    @Published var didEnableLocation = false
    
    @Published var mapStyle : MKMapType = .standard
    @Published var route: MKRoute?
    @Published var searchQuery: String = ""
    @Published var searchResults: [MKMapItem] = []
    @Published var showDropdown: Bool = false
    
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    let defaultLocation = CLLocation(latitude: 44.04272, longitude: -123.06726)

    @Published var position: MapCameraPosition = .camera(.init(centerCoordinate: CLLocationCoordinate2D(latitude: 44.04272, longitude: -123.06726), distance: 1000))
    
    func requestUserLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    
    func updateRegion(with location: CLLocation?) {
        if let coordinate = location?.coordinate {
            position = .camera(.init(centerCoordinate: coordinate, distance: 1000))
        } else {
            position = .camera(.init(centerCoordinate: CLLocationCoordinate2D(latitude: 44.04272, longitude: -123.06726), distance: 1000))
        }
    }
    
    @Published var shouldRecenterMap = true
    
    // Respond to authorization status changes
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
            case .notDetermined:
                // Request when-in-use authorization initially
                manager.requestWhenInUseAuthorization()
            case .restricted, .denied:
                // Handle case where user has denied or restricted location services
                didEnableLocation = false

                break
            case .authorizedWhenInUse, .authorizedAlways:
                // Permission granted, start location updates
                print("User has authorized location")
                didEnableLocation = true
                manager.requestLocation()
            @unknown default:
                didEnableLocation = false

                break
        }
    }
    
    func updateLocationAndGetDirections(destination: CLLocationCoordinate2D) async -> MKRoute? {
        locationManager.requestLocation() // This triggers an async update. Consider handling this properly.
        
        // Await for user location to be updated. This is conceptual; you need a way to wait for the location update callback.
        guard let userLocation = self.userLocation else { return nil }

        let request = MKDirections.Request()
        request.transportType = .walking
        request.source = MKMapItem(placemark: .init(coordinate: userLocation.coordinate ))
        request.destination = MKMapItem(placemark: .init(coordinate: destination))
        
        let directions = MKDirections(request: request)
        do {
            let response = try await directions.calculate()
            return response.routes.first
        } catch {
            print("Failed to calculate directions: \(error)")
            return nil
        }
    }
    
    
    // Handle the single location update
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        DispatchQueue.main.async { [weak self] in
            self?.userLocation = location
            print("Users location: ", location)

        }
    }
    
    // Handle possible location errors
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }

    
    func formatAddress(_ address: CNPostalAddress) -> String {
        let formatter = CNPostalAddressFormatter()
        formatter.style = .mailingAddress
        return formatter.string(from: address).replacingOccurrences(of: "\n", with: ", ")
    }
    
    func performSearch(query: String, completion: @escaping ([MKMapItem]?, Error?) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let search = MKLocalSearch(request: request)
        
        search.start { response, error in
            if let error = error {
                print("Search error: \(error.localizedDescription)")
                completion(nil, error)
                self.resetSearch()
                return
            }
            
            if let response = response {
                let sourceLocation = self.userLocation?.coordinate ?? self.defaultLocation.coordinate
                
                let sortedResults = response.mapItems.sorted { item1, item2 in
                    let distance1 = CLLocation(latitude: item1.placemark.coordinate.latitude, longitude: item1.placemark.coordinate.longitude)
                        .distance(from: CLLocation(latitude: sourceLocation.latitude, longitude: sourceLocation.longitude))
                    let distance2 = CLLocation(latitude: item2.placemark.coordinate.latitude, longitude: item2.placemark.coordinate.longitude)
                        .distance(from: CLLocation(latitude: sourceLocation.latitude, longitude: sourceLocation.longitude))
                    return distance1 < distance2
                }
                
                self.searchResults = sortedResults
                self.showDropdown = !sortedResults.isEmpty
                
                completion(sortedResults, nil)
            } else {
                completion(nil, nil)
            }
        }
    }

    
    func getDirections(to item: MKMapItem) {
        route = nil
        let request = MKDirections.Request()
        request.transportType = .walking
        
        let sourceLocation = self.userLocation ?? self.defaultLocation
        request.source = MKMapItem(placemark: .init(coordinate: sourceLocation.coordinate))
        request.destination = item
        showDropdown = false

        Task {
            let directions = MKDirections(request: request)
            do {
                let response = try await directions.calculate()
                DispatchQueue.main.async {
                    withAnimation {
                        self.route = response.routes.first
                    }
                    print("Selected location details: \(item.name ?? "Unknown"), \(item.phoneNumber ?? "No phone number available")")
                }
            } catch {
                print("Failed to calculate directions: \(error.localizedDescription)")
            }
        }
    }
    
    func resetSearch() {
        DispatchQueue.main.async {
            self.searchQuery = ""
            self.searchResults = []
            self.showDropdown = false
            self.route = nil
        }
    }

}

// Extension to convert degrees to radians
extension Double {
    var degreesToRadians: Self { self * .pi / 180 }
}
