//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import Foundation

struct Weather {
    var description: String
    var temperature: Float
    var minimumTemperature: Float
    var maximumTemperature: Float
    var humidity: Float
    var pressure: Float
    var sunrise: Date
    var sunset: Date
    
    init(fromJSON: ForecastJSON) {
        let currently = fromJSON.currently
        let today = fromJSON.daily.data[0]
        description = currently.summary
        temperature = currently.temperature
        minimumTemperature = today.temperatureLow
        maximumTemperature = today.temperatureHigh
        humidity = currently.humidity
        pressure = currently.pressure
        sunrise = Date.init(timeIntervalSince1970: Double(today.sunriseTime))
        sunset = Date.init(timeIntervalSince1970: Double(today.sunsetTime))
    }
}

// MARK: Dark Sky API JSON structures for current weather web service

struct ForecastJSON: Decodable {
    let currently: CurrentlyJSON
    let daily: DailyJSON
}

struct CurrentlyJSON: Decodable {
    let summary: String
    let temperature: Float
    let humidity: Float
    let pressure: Float
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
}

