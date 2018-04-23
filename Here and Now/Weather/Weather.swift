//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import Foundation

struct Weather {
    var currentSummary: String
    var daySummary: String
    var temperature: Float
    var apparentTemperature: Float
    var minimumTemperature: Float
    var maximumTemperature: Float
    var humidity: Float
    var precipitationProbability: Float
    var precipitationType: String?
    var pressure: Float
    var cloudCover: Float
    var sunrise: Date
    var sunset: Date
    var metricSystemUnits: Bool
    
    init(fromJSON: ForecastJSON, metricSystemUnits: Bool) {
        let currently = fromJSON.currently
        let hourly = fromJSON.hourly
        let today = fromJSON.daily.data[0]
        currentSummary = currently.summary
        daySummary = hourly.summary
        temperature = currently.temperature
        apparentTemperature = currently.apparentTemperature
        minimumTemperature = today.temperatureLow
        maximumTemperature = today.temperatureHigh
        humidity = currently.humidity
        precipitationProbability = today.precipProbability
        precipitationType = today.precipType
        pressure = currently.pressure
        cloudCover = currently.cloudCover
        sunrise = Date.init(timeIntervalSince1970: Double(today.sunriseTime))
        sunset = Date.init(timeIntervalSince1970: Double(today.sunsetTime))
        self.metricSystemUnits = metricSystemUnits
    }
}

// MARK: Dark Sky API JSON structures for current weather web service

struct ForecastJSON: Decodable {
    let currently: CurrentlyJSON
    let hourly: HourlyJSON
    let daily: DailyJSON
}

struct CurrentlyJSON: Decodable {
    let summary: String
    let temperature: Float
    let apparentTemperature: Float
    let humidity: Float
    let pressure: Float
    let cloudCover: Float
}

struct HourlyJSON: Decodable {
    let summary: String
}

struct DailyJSON: Decodable {
    let data: Array<DailyDataJSON>
}

struct DailyDataJSON: Decodable {
    let time: Int
    let sunriseTime: Int
    let sunsetTime: Int
    let temperatureLow: Float
    let temperatureHigh: Float
    let precipProbability: Float
    let precipType: String?
}

