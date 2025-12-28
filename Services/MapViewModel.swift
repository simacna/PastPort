//
//  MapViewModel.swift
//  PastPort
//
//  Created by Sina S on 12/28/25.
//

import Foundation
import MapKit

class MapViewModel: ObservableObject {
    // This tells the UI to refresh whenever the list changes
    @Published var locations: [PointOfInterest] = []
    
    init() {
        loadData()
    }
    
    func loadData() {
        // Use our Chef (Service) to get the ingredients (Model)
        self.locations = DataService.loadSeedData()
    }
}
