//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import Foundation

struct Weather {
    var placeName: String
    var description: String
    var temperature: Float
    var minimumTemperature: Float
    var maximumTemperature: Float
    var humidity: Int
    var pressure: Float
    var sunrise: Date
    var sunset: Date
    
    init(fromJSON: CurrentWeatherJSON) {
        let weather = fromJSON.weather[0]
        let main = fromJSON.main
        let sys = fromJSON.sys
        placeName = fromJSON.name
        description = weather.description
        temperature = main.temp
        minimumTemperature = main.temp_min
        maximumTemperature = main.temp_max
        humidity = main.humidity
        pressure = main.pressure
        sunrise = Date.init(timeIntervalSince1970: Double(sys.sunrise))
        sunset = Date.init(timeIntervalSince1970: Double(sys.sunset))
    }
}

// MARK: OpenWeatherMap JSON structures for current weather web service

struct CurrentWeatherJSON: Decodable {
    let name: String
    let sys: SysJSON
    let weather: [WeatherJSON]
    let main: MainJSON
}

struct SysJSON: Decodable {
    let sunrise: Int
    let sunset: Int
}

struct WeatherJSON: Decodable {
    let main: String
    let description: String
}

struct MainJSON: Decodable {
    let temp: Float
    let pressure: Float
    let humidity: Int
    let temp_min: Float
    let temp_max: Float
}
