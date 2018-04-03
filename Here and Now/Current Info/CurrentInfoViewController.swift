//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import CoreLocation
import GoogleMaps
import RxSwift
import UIKit

class CurrentInfoViewController: UIViewController, CurrentInfoController {
    private var components: CurrentInfoComponents?
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
    
    override func viewWillDisappear(_ animated: Bool) {
        if let components = components {
            stop(components: components)
        }
        disposeBag = DisposeBag()
        super.viewDidDisappear(animated)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // Prevent flash of map background while loading tiles after screen dimension change
        components?.maskView.alpha = 1.0
    }
}

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

