//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import CoreLocation
import EasyPeasy
import GoogleMaps
import os.log
import RxCocoa
import RxCoreLocation
import RxSwift

class CurrentInfoComponent: ViewComponent {
    
    struct Inputs {
        let authorization: Observable<CLAuthorizationEvent>
        let initialLocation: Observable<CLLocation?>
        let date: Observable<Date>
        let viewTransition: BehaviorSubject<Void>
    }
    
    let view = UIView()
    private let disposedBy: DisposeBag
    private let weatherService = WeatherService(apiKey: Config().darkSkyApiKey)
    private let geocoder = CLGeocoder()
    private let map: MapComponent
    private let mask = UIView()
    private let hud: HeadUpDisplayComponent

    required init(disposedBy: DisposeBag) {
        self.disposedBy = disposedBy

        map = MapComponent(disposedBy: disposedBy)
        view.addSubview(map.view)
        map.view.easy.layout(Edges())
        
        // Hide map during transitions
        mask.backgroundColor = UIColor.black
        view.addSubview(mask)
        mask.easy.layout(Edges())

        hud = HeadUpDisplayComponent(disposedBy: disposedBy)
        view.addSubview(hud.view)
        hud.view.easy.layout(Edges())
        hud.view.fadeOut()
    }
    
    func start(_ inputs: Inputs) {
        let mapSources = map.start(
            MapComponent.Inputs(
                authorization: inputs.authorization,
                initialLocation: inputs.initialLocation,
                date: inputs.date
            )
        )
        
        mapSources.didFinishTileRendering
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { _ in self.mask.fadeOut(duration: 0.5) })
            .disposed(by: disposedBy)
        
        mapSources.isMoving
            .filter { $0 }
            .asDriver(onErrorJustReturn: true)
            .drive(onNext: { _ in self.hud.view.fadeOut(duration: 0.5) })
            .disposed(by: disposedBy)
        
        let idleCameraPosition = mapSources.idleAt.share()
        let idleCameraLocation = idleCameraPosition.map(toLocation).share()
        
        let placemark = placemarkForLocation(reverseGeocode: geocoder.rx.reverseGeocode)(idleCameraLocation)
            .do(onNext: { print($0) })
            .share()
        
        let uiScheme = uiSchemeDriver(forLocation: idleCameraLocation,
                                             date: inputs.date.throttle(60, scheduler: MainScheduler.instance))
        
        let weather = checkWeather(fetch: self.weatherService.fetchCurrentWeather)(
            idleCameraLocation, currentDate(), Locale.current.usesMetricSystem)
            .retry(.exponentialDelayed(maxCount: 50, initial: 0.5, multiplier: 1.0), scheduler: MainScheduler.instance)
            .do(onNext: { print($0) })
            .share()
        
        hud.start(
            HeadUpDisplayComponent.Inputs(
                uiScheme: uiScheme,
                date: inputs.date,
                placemark: placemark,
                weather: weather
            )
        )
        
        uiScheme
            .drive(onNext: { self.mask.backgroundColor = $0.style().defaultBackgroundColor })
            .disposed(by: disposedBy)

        inputs.viewTransition
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { _ in
                // Prevent flash of map background when reloading tiles after
                // screen dimension or aspect ratio change
                self.mask.fadeIn()
            })
            .disposed(by: disposedBy)
        
        shouldShowHud(whenWeatherFetched: weather, placemarkAvailable: placemark)
            .asDriver(onErrorDriveWith: SharedSequence.empty())
            .drive(onNext: { _ in self.hud.view.fadeIn(duration: 0.5) })
            .disposed(by: disposedBy)
    }
}

extension CurrentInfoComponent {
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
                       placemarkAvailable: Observable<CLPlacemark>) -> Observable<Void> {
        return Observable.zip(whenWeatherFetched, placemarkAvailable) { _, _ in () }
    }
}
