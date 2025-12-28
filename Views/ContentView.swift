//
//  ContentView.swift
//  PastPort
//
//  Created by Sina S on 12/28/25.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject var viewModel = MapViewModel()
    
    // Set the initial camera position to St. Marks, NYC
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7289, longitude: -73.9888),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: viewModel.locations) { poi in
            MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: poi.location.latitude, longitude: poi.location.longitude)) {
                VStack {
                    Image(systemName: "book.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.red)
                    Text(poi.name)
                        .font(.caption)
                        .bold()
                }
            }
        }
        .ignoresSafeArea()
    }
}
