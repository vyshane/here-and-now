//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import CoreLocation
import GoogleMaps
import RxSwift
import UIKit

class CurrentInfoViewController: UIViewController, CurrentInfoController {
    private var components: Components?
    private var disposeBag = DisposeBag()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        components = initComponents(addToRootView: view)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let components = components {
            start(components: components, disposedBy: disposeBag)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if let components = components {
            stop(components: components)
        }
        disposeBag = DisposeBag()
        super.viewDidDisappear(animated)
    }
}

struct Components {
    let locationManager: CLLocationManager
    let weatherService: WeatherService
    let mapView: GMSMapView
    let timeLabel: UILabel
    let placeLabel: UILabel
    let weatherDescriptionLabel: UILabel
    let currentTemperatureLabel: UILabel
    
    // Temporarily hides map to prevent background flash while map tiles are loading
    let maskView: UIView
}

