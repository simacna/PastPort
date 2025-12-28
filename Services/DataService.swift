//
//  DataService.swift
//  PastPort
//
//  Created by Sina S on 12/28/25.
//

import Foundation

class DataService {
    // A simple function to load and parse the local JSON file
    static func loadSeedData() -> [PointOfInterest] {
        // 1. Locate the file in the app bundle
        guard let url = Bundle.main.url(forResource: "seedData", withExtension: "json") else {
            print("JSON file not found")
            return []
        }
        
        do {
            // 2. Load the raw data
            let data = try Data(contentsOf: url)
            
            // 3. Decode the JSON into our Swift Structs
            let decoder = JSONDecoder()
            let pois = try decoder.decode([PointOfInterest].self, from: data)
            return pois
        } catch {
            print("Error decoding JSON: \(error)")
            return []
        }
    }
}
