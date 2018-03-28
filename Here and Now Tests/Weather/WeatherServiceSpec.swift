//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import CoreLocation
import Fakery
import Foundation
import Mockingjay
import Nimble
import Quick
import RxBlocking
@testable import Here_and_Now

// Integration tests for WeatherService
class WeatherServiceSpec: QuickSpec {
    override func spec() {
        
        let faker = Faker(locale: "en-AU")
        let apiKey = faker.lorem.characters(amount: 16)
        let latitude = 35.02
        let longitude = 139.01
        let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let serviceUri = "https://api.darksky.net/forecast/\(apiKey)/\(latitude),\(longitude)"
        
        let weatherService = WeatherService(apiKey: apiKey)

        describe("the WeatherService") {
            describe("when fetching the current weather") {
                it("should return an error if the web service responds with a HTTP code that is not 2xx") {
                    self.stub(uri(serviceUri), http(500))
                    expect {
                        try weatherService
                            .fetchCurrentWeather(coordinates: coordinates)
                            .toBlocking()
                            .first()
                    }
                    .to(throwError())
                }
                it("should return an error if the web service responds with a JSON payload that cannot be decoded") {
                    let invalidJSON = "{ \"weather\": [], \"main\": {}, }"
                    self.stub(uri(serviceUri), jsonData(invalidJSON.data(using: String.Encoding.utf8)!))
                    expect {
                        try weatherService
                            .fetchCurrentWeather(coordinates: coordinates)
                            .toBlocking()
                            .first()
                        }
                        .to(throwError())
                }
                it("should return the weather if the web service responds with a valid JSON payload") {
                    // Sample JSON from https://openweathermap.org/current#geo
                    let validJSON = """
                        {
                            "latitude": 37.33233141,
                            "longitude": -122.0312186,
                            "timezone": "America\\/Los_Angeles",
                            "currently": {
                                "time": 1522242779,
                                "summary": "Clear",
                                "icon": "clear-night",
                                "nearestStormDistance": 420,
                                "nearestStormBearing": 351,
                                "precipIntensity": 0,
                                "precipProbability": 0,
                                "temperature": 9.25,
                                "apparentTemperature": 9.25,
                                "dewPoint": 6.08,
                                "humidity": 0.81,
                                "pressure": 1021.69,
                                "windSpeed": 0.75,
                                "windGust": 1.18,
                                "windBearing": 42,
                                "cloudCover": 0.03,
                                "uvIndex": 0,
                                "visibility": 16.09,
                                "ozone": 338.71
                            },
                            "minutely": {},
                            "hourly": {},
                            "daily": {
                                "summary": "No precipitation throughout the week, with temperatures falling to 22\\u00b0C next Wednesday.",
                                "icon": "clear-day",
                                "data": [
                                    {
                                        "time": 1522220400,
                                        "summary": "Clear throughout the day.",
                                        "icon": "clear-day",
                                        "sunriseTime": 1522245616,
                                        "sunsetTime": 1522290490,
                                        "moonPhase": 0.41,
                                        "precipIntensity": 0.0076,
                                        "precipIntensityMax": 0.0356,
                                        "precipIntensityMaxTime": 1522267200,
                                        "precipProbability": 0.21,
                                        "precipType": "rain",
                                        "temperatureHigh": 26.13,
                                        "temperatureHighTime": 1522278000,
                                        "temperatureLow": 13.28,
                                        "temperatureLowTime": 1522332000,
                                        "apparentTemperatureHigh": 26.13,
                                        "apparentTemperatureHighTime": 1522278000,
                                        "apparentTemperatureLow": 13.28,
                                        "apparentTemperatureLowTime": 1522332000,
                                        "dewPoint": 7.79,
                                        "humidity": 0.58,
                                        "pressure": 1020.56,
                                        "windSpeed": 1.28,
                                        "windGust": 4.98,
                                        "windGustTime": 1522281600,
                                        "windBearing": 345,
                                        "cloudCover": 0.02,
                                        "uvIndex": 7,
                                        "uvIndexTime": 1522267200,
                                        "visibility": 16.09,
                                        "ozone": 333.25,
                                        "temperatureMin": 8.91,
                                        "temperatureMinTime": 1522234800,
                                        "temperatureMax": 26.13,
                                        "temperatureMaxTime": 1522278000,
                                        "apparentTemperatureMin": 8.91,
                                        "apparentTemperatureMinTime": 1522234800,
                                        "apparentTemperatureMax": 26.13,
                                        "apparentTemperatureMaxTime": 1522278000
                                    }
                                ]
                            }
                        }
                    """
                    self.stub(uri(serviceUri), jsonData(validJSON.data(using: String.Encoding.utf8)!))
                    do {
                        let weather = try weatherService
                            .fetchCurrentWeather(coordinates: coordinates)
                            .toBlocking()
                            .first()
                        expect(weather).toNot(beNil())
                        expect(weather?.description) == "Clear"
                        expect(weather?.temperature) == 9.25
                        expect(weather?.minimumTemperature) == 8.91
                        expect(weather?.maximumTemperature) == 21.13
                        expect(weather?.humidity) == 0.81
                        expect(weather?.pressure) == 1021.69
                        expect(weather?.sunrise) == Date(timeIntervalSince1970: Double(1522245616))
                        expect(weather?.sunset) == Date(timeIntervalSince1970: Double(1522290490))
                    } catch {
                    }
                }
            }
        }
    }
}
