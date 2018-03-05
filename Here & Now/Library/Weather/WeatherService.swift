import Foundation
import CoreLocation
import RxSwift

class WeatherService {
    
    let baseServiceURL = "https://api.openweathermap.org/data/2.5/"
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func fetchCurrentWeather(coordinates: CLLocationCoordinate2D) -> Single<Weather> {
        let url = URL(string:
            "\(baseServiceURL)weather" +
            "?APPID=\(self.apiKey)" +
            "&lat=\(coordinates.latitude)" +
            "&lon=\(coordinates.longitude)"
        )
        return URLSession.shared.rx
            .data(request: URLRequest(url: url!))
            .map { try JSONDecoder().decode(CurrentWeatherJSON.self, from: $0) }
            .map { Weather(fromJSON: $0) }
            .asSingle()
    }
}

