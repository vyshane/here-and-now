//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import CoreLocation
import EasyPeasy
import FittableFontLabel
import GoogleMaps

struct CurrentInfoComponents {
    let locationManager: CLLocationManager
    let weatherService: WeatherService
    let mapView: GMSMapView
    let hud: UIView
    let timeLabel: UILabel
    let dateLabel: UILabel
    let summaryLabel: UILabel
    let currentTemperatureLabel: UILabel
    let minimumTemperatureLabel: UILabel
    let maximumTemperatureLabel: UILabel
    let lowLabel: UILabel
    let highLabel: UILabel
    let currentHumidityLabel: UILabel
    
    // Temporarily hides map to prevent background flash while map tiles are loading
    let maskView: UIView
}
