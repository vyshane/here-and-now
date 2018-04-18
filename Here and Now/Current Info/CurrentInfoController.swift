//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import CoreLocation
import EasyPeasy
import GoogleMaps
import RxCoreLocation
import RxSwift

protocol CurrentInfoController { }

extension CurrentInfoController {
    
    // MARK: Lifecycle Methods
    
    func initComponents(addToRootView: UIView, disposedBy: DisposeBag) -> CurrentInfoComponents {
        
        let map = MapComponent(disposedBy: disposedBy)
        addToRootView.addSubview(map.view)
        map.view.easy.layout(Edges())

        let maskView: UIView = {
            let maskView = UIView()
            maskView.backgroundColor = UIColor.black
            addToRootView.addSubview(maskView)
            maskView.easy.layout(Edges())
            return maskView
        }()
        
        let hud = HeadUpDisplayComponent(disposedBy: disposedBy)
        addToRootView.addSubview(hud.view)
        hud.view.easy.layout(Edges())
        fadeOut(view: hud.view, duration: 0)
        
        return CurrentInfoComponents(
            locationManager: CLLocationManager(),
            weatherService: WeatherService(apiKey: Config().darkSkyApiKey),
            map: map,
            hud: hud,
            maskView: maskView
        )
    }
    
    func start(components: CurrentInfoComponents, disposedBy: DisposeBag) -> Void {
        components.locationManager.requestWhenInUseAuthorization()
        components.locationManager.distanceFilter = 10
        components.locationManager.startUpdatingLocation()
        
        let mapSources = components.map.start(
            MapComponent.Inputs(
                authorization: components.locationManager.rx.didChangeAuthorization.asObservable(),
                location: components.locationManager.rx.location.take(1),
                date: currentDate()
            )
        )
        
        mapSources.didFinishTileRendering
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { _ in self.fadeOut(view: components.maskView, duration: 0.5) })
            .disposed(by: disposedBy)
        
        mapSources.willMove
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { _ in self.fadeOut(view: components.hud.view, duration: 0.5) })
            .disposed(by: disposedBy)
        
        let date = currentDate().share()
        let idleCameraPosition = mapSources.idleAt.share()
        let idleCameraLocation = idleCameraPosition.map(toLocation).share()
        let placemark = placemarkForLocation(reverseGeocode: CLGeocoder().rx.reverseGeocode)(idleCameraLocation).share()
        
        let weather = checkWeather(fetch: components.weatherService.fetchCurrentWeather)(
                idleCameraPosition.map(toLocation), currentDate(), Locale.current.usesMetricSystem)
            .retry(.exponentialDelayed(maxCount: 50, initial: 0.5, multiplier: 1.0), scheduler: MainScheduler.instance)
            .share()

        components.hud.start(
            HeadUpDisplayComponent.Inputs(
                uiScheme: uiScheme(fromLocation: idleCameraLocation,
                                   date: date.throttle(60, scheduler: MainScheduler.instance)),
                date: date,
                placemark: placemark,
                weather: weather
            )
        )

        shouldShowHud(whenWeatherFetched: weather, mapCameraIdleAt: idleCameraPosition)
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { ok in
                if (ok) {
                    self.fadeIn(view: components.hud.view, duration: 0.5)
                }
            })
            .disposed(by: disposedBy)
    }
    
    func stop(components: CurrentInfoComponents) -> Void {
        fadeIn(view: components.maskView, duration: 0)
        components.locationManager.stopUpdatingLocation()
    }
    
    typealias FetchWeather = (CLLocationCoordinate2D, Bool) -> Single<Weather>
    
    func checkWeather(fetch: @escaping FetchWeather)
        -> (Observable<CLLocation>, Observable<Date>, Bool)
        -> Observable<Weather> {
        return { (location, date, useMetricSystem) in
            return Observable
                .combineLatest(location, date)
                .distinctUntilChanged { (a, b) in
                    let insufficientTimeElapsed: (Date, Date) -> Bool = { $1.timeIntervalSince($0) < 5 * 60 }
                    let insignificantMovement: (CLLocation, CLLocation) -> Bool = { $0.distance(from: $1) < 20 }
                    return insignificantMovement(a.0, b.0) && insufficientTimeElapsed(a.1, b.1)
                }
                .map { $0.0 }
                .flatMapLatest { fetch($0.coordinate, useMetricSystem) }
        }
    }

    func shouldShowHud(whenWeatherFetched: Observable<Weather>,
                       mapCameraIdleAt: Observable<GMSCameraPosition>) -> Observable<Bool> {
        return Observable
            .zip(whenWeatherFetched, mapCameraIdleAt)
            .map { _ in true }
    }
    
    func fadeIn(view: UIView, duration: TimeInterval) -> Void {
        if (view.alpha < 1.0) {
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: { view.alpha = 1.0 })
        }
    }
    
    func fadeOut(view: UIView, duration: TimeInterval) -> Void {
        if (view.alpha > 0.0) {
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: { view.alpha = 0.0 })
        }
    }
}
