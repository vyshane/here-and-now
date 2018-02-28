import Foundation
import CoreLocation
import RxSwift

class WeatherService: WebService {
    
    let baseServiceURL = "https://api.openweathermap.org/data/2.5/"
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func fetchCurrentWeather(coordinates: CLLocationCoordinate2D) -> Single<Weather?> {
        let url = URL(string: "\(baseServiceURL)weather?APPID=\(self.apiKey)" +
            "&lat=\(coordinates.latitude)&lon=\(coordinates.longitude)")
        return get(url: url!)
            .map { Weather(fromJSON: $0) }
    }
}
