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
            startComponents(components: components, disposeBag: disposeBag)
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
        // Map
        GMSServices.provideAPIKey(Config().googleMobileServicesAPIKey)
        let mapView = GMSMapView()
        rootView.addSubview(mapView)
        mapView.easy.layout(Edges())
        
        // Time
        let timeLabel = UILabel()
        rootView.addSubview(timeLabel)
        timeLabel.easy.layout(Width(200), Height(120))

        return Components(
            locationManager: CLLocationManager(),
            mapView: mapView,
            timeLabel: timeLabel
        )
    }

    func startComponents(components: Components, disposeBag: DisposeBag) -> Void {
        // Location
        components.locationManager.requestWhenInUseAuthorization()
        components.locationManager.startUpdatingLocation()
        
        // Enable or disable map depending on access to location services
        components.locationManager.rx.didChangeAuthorization
            .map { self.isMapVisible(authorizationStatus: $1) }
            .bind(to: components.mapView.rx.isHidden)
            .disposed(by: disposeBag)
        
        // Update map location
        components.locationManager.rx.location
            .flatMap { self.cameraPosition(location: $0) }
            .bind(to: components.mapView.rx.cameraToAnimate)
            .disposed(by: disposeBag)
        
        // Time
        currentDate()
            .map { formattedTime(date: $0) }
            .bind(to: components.timeLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
    func isMapVisible(authorizationStatus: CLAuthorizationStatus) -> Bool {
        switch (authorizationStatus) {
            case .denied: return true
            case _: return false
        }
    }

    func cameraPosition(location: CLLocation?) -> Observable<GMSCameraPosition> {
        if let location = location {
            return Observable.just(GMSCameraPosition.camera(withTarget: location.coordinate, zoom: 17))
        } else {
            return Observable.empty()
        }
    }
}
