//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import CoreLocation
import EasyPeasy
import FittableFontLabel
import GoogleMaps

struct CurrentInfoComponents {
    let locationManager: CLLocationManager
    let weatherService: WeatherService
    let map: MapComponent
    let hud: HeadUpDisplayComponent

    // Temporarily hides map to prevent background flash while map tiles are loading
    let maskView: UIView
}
