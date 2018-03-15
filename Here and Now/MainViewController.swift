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
    
    // Temporarily hides map to prevent background flash while map tiles are loading
    let maskView: UIView
}

protocol MainController { }

extension MainController {
    
    // MARK: Lifecycle Methods
    
    func initComponents(addToRootView: UIView) -> Components {
        let mapView: GMSMapView = {
            GMSServices.provideAPIKey(Config().googleMobileServicesAPIKey)
            let mapView = GMSMapView()
            mapView.settings.setAllGesturesEnabled(false)
            addToRootView.addSubview(mapView)
            mapView.easy.layout(Edges())
            return mapView
        }()
        
        let maskView: UIView = {
            let maskView = UIView()
            maskView.backgroundColor = UIColor.black
            addToRootView.addSubview(maskView)
            maskView.easy.layout(Edges())
            return maskView
        }()
        
        let timeLabel: UILabel = {
            let timeLabel = UILabel()
            timeLabel.font = UIFont.systemFont(ofSize: 120, weight: .thin)  // San Fransisco
            timeLabel.textAlignment = .center
            addToRootView.addSubview(timeLabel)
            timeLabel.easy.layout(
                TopMargin(56),
                LeftMargin(16),
                RightMargin(16)
            )
            return timeLabel
        }()

        return Components(
            locationManager: CLLocationManager(),
            weatherService: WeatherService(apiKey: Config().openWeatherMapAPIKey),
            mapView: mapView,
            timeLabel: timeLabel,
            maskView: maskView
        )
    }

    func start(components: Components, disposedBy: DisposeBag) -> Void {
        // Location
        components.locationManager.requestWhenInUseAuthorization()
        components.locationManager.startUpdatingLocation()
        
        formatCurrentTime(fromDate: currentDate())
            .bind(to: components.timeLabel.rx.text)
            .disposed(by: disposedBy)
        
        uiScheme(forLocation: components.locationManager.rx.location, date: currentDate())
            .subscribe(onNext: {
                components.timeLabel.textColor = $0.style().timeLabelColor
                components.mapView.mapStyle = $0.style().mapStyle
                components.maskView.backgroundColor = $0.style().defaultBackgroundColor
            })
            .disposed(by: disposedBy)
        
        shouldHideMap(forAuthorizationEvent: components.locationManager.rx.didChangeAuthorization.asObservable())
            .bind(to: components.mapView.rx.isHidden)
            .disposed(by: disposedBy)
        
        shouldHideMaskView(whenLocationReceived: components.locationManager.rx.location)
            .subscribe({ _ in
                if (components.maskView.alpha > 0) {
                    UIView.animate(withDuration: 0.5,
                                   delay: 1.0,
                                   options: .curveEaseOut,
                                   animations: { components.maskView.alpha = 0.0 })
                }
            })
            .disposed(by: disposedBy)

        mapCameraPosition(forLocation: components.locationManager.rx.location)
            .bind(to: components.mapView.rx.cameraToAnimate)
            .disposed(by: disposedBy)
    }
    
    func stop(components: Components) -> Void {
        components.maskView.alpha = 1.0
        components.locationManager.stopUpdatingLocation()
    }
    
    // MARK: UI State Changes
    
    func shouldHideMap(forAuthorizationEvent: Observable<CLAuthorizationEvent>) -> Observable<Bool> {
        return forAuthorizationEvent.map {
            switch ($0.status) {
                case .denied: return true
                case _: return false
            }
        }
    }
    
    func shouldHideMaskView(whenLocationReceived: Observable<CLLocation?>) -> Observable<Bool> {
        return whenLocationReceived.map { _ in true }
    }
    
    func uiScheme(forLocation: Observable<CLLocation?>, date: Observable<Date>) -> Observable<UIScheme> {
        return Observable.zip(forLocation, date) { (l, d) in
            if let location = l,
                let isDaytime = isDaytime(date: d, coordinate: location.coordinate),
                let scheme: UIScheme = isDaytime ? .light : .dark {
                return scheme
            }
            return .light
        }
    }

    func mapCameraPosition(forLocation: Observable<CLLocation?>) -> Observable<GMSCameraPosition> {
        let cameraPosition: (CLLocation?) -> Observable<GMSCameraPosition> = {
            if let location = $0 {
                return Observable.just(GMSCameraPosition.camera(withTarget: location.coordinate, zoom: 14))
            }
            return Observable.never()
        }
        return forLocation.flatMap { cameraPosition($0) }
    }

    func formatCurrentTime(fromDate: Observable<Date>) -> Observable<String> {
        return fromDate.map {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "hh:mm"
            return dateFormatter.string(from: $0)
        }
    }
}
