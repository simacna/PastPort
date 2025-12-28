//
//  PointOfInterest.swift
//  PastPort
//
//  Created by Sina S on 12/28/25.
//

import Foundation
import CoreLocation

struct PointOfInterest: Codable, Identifiable {
    var id: String { poi_id }
    let poi_id: String
    let name: String
    let location: Coordinates
    let categories: [String]
    let radius_meters: Int
    let content: Content

    struct Coordinates: Codable {
        let latitude: Double
        let longitude: Double
    }

    struct Content: Codable {
        let title: String
        let summary: String
        let full_story: String
        let image_url: String
    }
}
