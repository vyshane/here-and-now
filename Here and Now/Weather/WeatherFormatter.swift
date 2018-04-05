//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import Foundation

class WeatherFormatter {
    
    static func format(description: String) -> String {
        let description = description.capitalized
        if description.lowercased() == "clear" {
            return "\(description) Sky"
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
