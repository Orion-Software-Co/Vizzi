//
//  NavigationView.swift
//  Vizzi
//
//  Created by Adrian Martushev on 1/26/25.
//

import SwiftUI
import MapKit
import CoreLocation
import Contacts


struct MapNavigationView: View {
    @EnvironmentObject var mapVM : MapViewModel
    @EnvironmentObject var currentUser : CurrentUserViewModel
    
    
    var body: some View {
        
        GeometryReader { reader in
            ZStack {
                
                Map(position: $mapVM.position) {
                    
                    UserAnnotation()
                    
                    if let route = mapVM.route {
                        MapPolyline(route)
                        .stroke(.blue, lineWidth: 5)
                    }
                }
                .mapStyle(mapVM.mapStyle == .standard ? .standard : .hybrid)
                .onChange(of: mapVM.userLocation) { _, newLocation in
                    if mapVM.shouldRecenterMap {
                        mapVM.updateRegion(with: newLocation)
                        mapVM.shouldRecenterMap = false
                    }
                }
                .mapStyle(.standard(pointsOfInterest: .excludingAll))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .onTapGesture {
                    mapVM.showDropdown = false
                }
                
                VStack {
                    SearchField(text: $mapVM.searchQuery, placeholder: "Search")
                        .padding(.top, 20)
                        .frame(maxWidth : 350)
                        .onChange(of: mapVM.searchQuery) { _, newQuery in
                            if !newQuery.isEmpty {
                                mapVM.performSearch(query: newQuery) { results, error in
                                    
                                }
                            } else {
                                mapVM.searchResults = []
                                mapVM.showDropdown = false
                            }
                        }
                    
                    if mapVM.showDropdown {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack {
                                ForEach(mapVM.searchResults, id: \.self) { item in
                                    
                                    VStack(spacing : 0) {
                                        Button(action: {
                                            mapVM.getDirections(to: item)
                                        }) {
                                            VStack {
                                                HStack {
                                                    VStack(alignment : .leading) {
                                                        Text(item.name ?? "Unknown Location")
                                                            .lineLimit(1)
                                                        if let postalAddress = item.placemark.postalAddress {
                                                            Text(mapVM.formatAddress(postalAddress))
                                                                .font(.system(size: 14))
                                                                .foregroundStyle(.secondary)
                                                                .lineLimit(2)
                                                        } else {
                                                            Text("Unknown Address")
                                                                .font(.system(size: 14))
                                                                .foregroundStyle(.secondary)
                                                        }
                                                    }
                                                    .multilineTextAlignment(.leading)

                                                    Spacer()
                                                    
                                                    Image(systemName : "chevron.right")
                                                }
                                                .foregroundStyle(.white)
                                                .padding()
                                            }
                                        }
                                        
                                        Divider()
                                            .padding(.vertical, 4)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical)
                        }
                        .frame(maxWidth: 350, maxHeight: 300)
                        .background(.regularMaterial)
                        .cornerRadius(8)
                        .shadow(radius: 5)
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            mapVM.requestUserLocation()
        }
    }
}

#Preview {
    MapNavigationView()
        .environmentObject(MapViewModel())
        .environmentObject(CurrentUserViewModel())

}
