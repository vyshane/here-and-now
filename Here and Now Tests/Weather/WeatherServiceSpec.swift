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
        
        let serviceUri = "https://api.openweathermap.org/data/2.5/weather" +
            "?APPID=\(apiKey)" +
            "&lat=\(latitude)" +
            "&lon=\(longitude)"
        
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
                          "coord": {
                            "lon": 139.01,
                            "lat": 35.02
                          },
                          "weather": [
                            {
                              "id": 800,
                              "main": "Clear",
                              "description": "clear sky",
                              "icon": "01n"
                            }
                          ],
                          "base": "stations",
                          "main": {
                            "temp": 285.514,
                            "pressure": 1013.75,
                            "humidity": 100,
                            "temp_min": 280.126,
                            "temp_max": 288.772,
                            "sea_level": 1023.22,
                            "grnd_level": 1013.75
                          },
                          "wind": {
                            "speed": 5.52,
                            "deg": 311
                          },
                          "clouds": {
                            "all": 0
                          },
                          "dt": 1485792967,
                          "sys": {
                            "message": 0.0025,
                            "country": "JP",
                            "sunrise": 1485726240,
                            "sunset": 1485763863
                          },
                          "id": 1907296,
                          "name": "Tawarano",
                          "cod": 200
                        }
                        """
                    self.stub(uri(serviceUri), jsonData(validJSON.data(using: String.Encoding.utf8)!))
                    do {
                        let weather = try weatherService
                            .fetchCurrentWeather(coordinates: coordinates)
                            .toBlocking()
                            .first()
                        expect(weather).toNot(beNil())
                        expect(weather?.description) == "clear sky"
                        expect(weather?.temperature) == 285.514
                        expect(weather?.minimumTemperature) == 280.126
                        expect(weather?.maximumTemperature) == 288.772
                        expect(weather?.humidity) == 100
                        expect(weather?.pressure) == 1013.75
                        expect(weather?.sunrise) == Date(timeIntervalSince1970: Double(1485726240))
                        expect(weather?.sunset) == Date(timeIntervalSince1970: Double(1485763863))
                    } catch {
                    }
                }
            }
        }
    }
}
