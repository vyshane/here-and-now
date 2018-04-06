//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import Foundation

class WeatherFormatter {
    
    static func format(description: String) -> String {
        let capitalizeFirst: (String) -> String = { $0.prefix(1).uppercased() + $0.dropFirst() }
        let description = capitalizeFirst(description.lowercased())
        if description == "Clear" {
            return "\(description) sky"
        }
        return description
    }
    
    static func format(temperature: Float) -> String {
        return String(Int(temperature.rounded())) + "°"
    }
    
    static func format(humidity: Float) -> String {
        return "\(String(Int((humidity * 100).rounded())))% rh"
    }
}
