//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import CoreLocation
import Foundation
import RxCocoa
import RxSwift

class WeatherService {
    
    let baseServiceURL = "https://api.darksky.net/"
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func fetchCurrentWeather(coordinates: CLLocationCoordinate2D, useMetricSystem: Bool = true) -> Single<Weather> {
        let url = URL(string:
            "\(baseServiceURL)forecast/\(self.apiKey)/" +
            "\(coordinates.latitude),\(coordinates.longitude)" +
            "?lang=en" +  // TODO
            "&units=" + (useMetricSystem ? "si" : "us")
        )
        return URLSession.shared.rx
            .data(request: URLRequest(url: url!))
            .map { try JSONDecoder().decode(ForecastJSON.self, from: $0) }
            .map { Weather(fromJSON: $0) }
            .asSingle()
    }
}

