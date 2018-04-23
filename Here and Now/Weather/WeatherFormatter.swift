//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import Foundation

class WeatherFormatter {
    
    static func format(currentSummary: String) -> String {
        let capitalizeFirst: (String) -> String = { $0.prefix(1).uppercased() + $0.dropFirst() }
        let summary = capitalizeFirst(currentSummary.lowercased())
        if summary == "Clear" {
            return "\(summary) sky"
        }
        return summary
    }
    
    static func format(daySummary: String) -> String {
        let withoutLastPeriod = daySummary.dropLast()
        return String(withoutLastPeriod)
    }
    
    static func format(temperature: Float) -> String {
        return String(Int(temperature.rounded())) + "°"
    }
    
    static func format(humidity: Float) -> String {
        return "\(String(Int((humidity * 100).rounded())))% humidity"
    }
    
    static func format(precipitationProbability: Float) -> String {
        return "\(String(Int((precipitationProbability * 100).rounded())))%"
    }
    
    static func format(precipitationType: String?) -> String {
        return precipitationType.map { "\($0.capitalized)?" } ?? "Precipitation?"
    }
}
