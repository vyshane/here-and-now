//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import CoreLocation
import EasyPeasy
import GoogleMaps
import RxCoreLocation
import RxGoogleMaps
import RxSwift
import UIKit

class MainViewController: UIViewController, MainController {
    private var components: Components?
    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        components = initComponents(rootView: view)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let components = components {
            startUI(currentDate: currentDate)(components, disposeBag)
        }
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disposeBag = DisposeBag()
    }
}

struct Components {
    let locationManager: CLLocationManager
    let mapView: GMSMapView
    let timeLabel: UILabel
}

protocol MainController { }

extension MainController {
    
    func initComponents(rootView: UIView) -> Components {
        // Time
        let timeLabel = UILabel()
        rootView.addSubview(timeLabel)
        timeLabel.easy.layout(Width(200), Height(120))

        // Map
        GMSServices.provideAPIKey(Config().googleMobileServicesAPIKey)
        let mapView = GMSMapView()
        rootView.addSubview(mapView)
        mapView.easy.layout(Edges())
        
        return Components(
            locationManager: CLLocationManager(),
            mapView: mapView,
            timeLabel: timeLabel
        )
    }

    func startUI(currentDate: @escaping CurrentDate) -> (_ components: Components, _ disposeBag: DisposeBag) -> Void {
        return { (c: Components, disposeBag: DisposeBag) in
            // Time
            currentDate()
                .map { formattedTime(date: $0) }
                .observeOn(MainScheduler())
                .subscribe(onNext: { t in c.timeLabel.text = t })
                .disposed(by: disposeBag)
            
            // Location
            c.locationManager.requestWhenInUseAuthorization()
            c.locationManager.startUpdatingLocation()
            
            // Map
            c.locationManager.rx.location
                .map { self.cameraPosition(location: $0) }
                .bind(to: c.mapView.rx.cameraToAnimate)
                .disposed(by: disposeBag)
        }
    }

    func cameraPosition(location: CLLocation?) -> GMSCameraPosition {
        if let location = location {
            return GMSCameraPosition.camera(withTarget: location.coordinate, zoom: 17)
        } else {
            // Default to Times Square, NYC
            return GMSCameraPosition.camera(withLatitude: 40.758896, longitude: -73.985130, zoom: 17)
        }
    }
}
