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
    
    init(fromJSON: CurrentWeatherJSON) {
        let weather = fromJSON.weather[0]
        let main = fromJSON.main
        placeName = fromJSON.name
        description = weather.description
        temperature = main.temp
        minimumTemperature = main.temp_min
        maximumTemperature = main.temp_max
        humidity = main.humidity
        pressure = main.pressure
    }
}

// MARK: OpenWeatherMap JSON structures for current weather web service

struct CurrentWeatherJSON: Decodable {
    let name: String
    let weather: [WeatherJSON]
    let main: MainJSON
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
