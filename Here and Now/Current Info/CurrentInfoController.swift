//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import CoreLocation
import EasyPeasy
import FittableFontLabel
import GoogleMaps
import RxCoreLocation
import RxGoogleMaps
import RxSwift
import RxSwiftExt
import UIKit

protocol CurrentInfoController { }

extension CurrentInfoController {
    
    // MARK: Lifecycle Methods
    
    func initComponents(addToRootView: UIView) -> CurrentInfoComponents {
        let mapView: GMSMapView = {
            GMSServices.provideAPIKey(Config().googleMobileServicesAPIKey)
            let mapView = GMSMapView()
            mapView.isBuildingsEnabled = true
            mapView.isMyLocationEnabled = true
            mapView.setMinZoom(2.0, maxZoom: 18.0)
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
        
        let hud: UIView = {
            let hud = UIView()
            hud.isUserInteractionEnabled = false
            addToRootView.addSubview(hud)
            hud.easy.layout(Edges())
            return hud
        }()
        
        let stackView: UIStackView = {
            let stackView = UIStackView()
            stackView.axis = .vertical
            hud.addSubview(stackView)
            stackView.easy.layout(
                Top(8),
                Left(16),
                Right(16)
            )
            return stackView
        }()
        
        let summaryLabel: UILabel = {
            let summaryLabel = FittableFontLabel()
            summaryLabel.textAlignment = .left
            stackView.addArrangedSubview(summaryLabel)
            // Fill width
            summaryLabel.font = UIFont.systemFont(ofSize: 180, weight: .light)
            summaryLabel.numberOfLines = 1
            summaryLabel.lineBreakMode = .byWordWrapping
            summaryLabel.maxFontSize = 64
            summaryLabel.minFontScale = 0.1
            summaryLabel.autoAdjustFontSize = true
            return summaryLabel
        }()
        
        stackView.setCustomSpacing(8, after: summaryLabel)
        
        let temperatureStackView: UIStackView = {
            let temperatureStackView = UIStackView()
            temperatureStackView.alignment = .center
            temperatureStackView.spacing = 16
            stackView.addArrangedSubview(temperatureStackView)
            return temperatureStackView
        }()

        let currentTemperatureLabel: UILabel = {
            let currentTemperatureLabel = UILabel()
            currentTemperatureLabel.textAlignment = .left
            temperatureStackView.addArrangedSubview(currentTemperatureLabel)
            currentTemperatureLabel.font = UIFont.systemFont(ofSize: 130, weight: .thin)
            currentTemperatureLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            return currentTemperatureLabel
        }()
        
        let minimumTemperatureLabel: UILabel = {
            let minimumTemperatureLabel = UILabel()
            minimumTemperatureLabel.font = UIFont.systemFont(ofSize: 28, weight: .regular)
            minimumTemperatureLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            temperatureStackView.addArrangedSubview(minimumTemperatureLabel)
            return minimumTemperatureLabel
        }()

        let lowLabel: UILabel = {
            let lowLabel = UILabel()
            lowLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            hud.addSubview(lowLabel)
            lowLabel.easy.layout(
                Left(16).to(currentTemperatureLabel),
                Top().to(minimumTemperatureLabel)
            )
            return lowLabel
        }()

        let maximumTemperatureLabel: UILabel = {
            let maximumTemperatureLabel = UILabel()
            maximumTemperatureLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            temperatureStackView.addArrangedSubview(maximumTemperatureLabel)
            maximumTemperatureLabel.font = UIFont.systemFont(ofSize: 28, weight: .regular)
            return maximumTemperatureLabel
        }()
        
        let highLabel: UILabel = {
            let highLabel = UILabel()
            highLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            hud.addSubview(highLabel)
            highLabel.easy.layout(
                Left(16).to(minimumTemperatureLabel),
                Top().to(maximumTemperatureLabel)
            )
            return highLabel
        }()
        
        let currentHumidityLabel: UILabel = {
            let currentHumidityLabel = UILabel()
            currentHumidityLabel.textAlignment = .left
            stackView.addArrangedSubview(currentHumidityLabel)
            currentHumidityLabel.font = UIFont.systemFont(ofSize: 64, weight: .light)
            return currentHumidityLabel
        }()
        
        let dateLabel: UILabel = {
            let dateLabel = UILabel()
            dateLabel.textAlignment = .center
            hud.addSubview(dateLabel)
            dateLabel.easy.layout(
                Right(8), Bottom(8)
            )
            dateLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)  // San Fransisco
            return dateLabel
        }()
        
        let timeLabel: UILabel = {
            let timeLabel = FittableFontLabel()
            timeLabel.textAlignment = .center
            hud.addSubview(timeLabel)
            timeLabel.easy.layout(
                Width().like(dateLabel), Right(8), Bottom(4).to(dateLabel)
            )
            // Fill width
            timeLabel.font = UIFont.systemFont(ofSize: 180, weight: .regular)
            timeLabel.numberOfLines = 1
            timeLabel.lineBreakMode = .byWordWrapping
            timeLabel.maxFontSize = 180
            timeLabel.minFontScale = 0.1
            timeLabel.autoAdjustFontSize = true
            return timeLabel
        }()
        
        return CurrentInfoComponents(
            locationManager: CLLocationManager(),
            weatherService: WeatherService(apiKey: Config().darkSkyApiKey),
            mapView: mapView,
            hud: hud,
            timeLabel: timeLabel,
            dateLabel: dateLabel,
            summaryLabel: summaryLabel,
            currentTemperatureLabel: currentTemperatureLabel,
            minimumTemperatureLabel: minimumTemperatureLabel,
            maximumTemperatureLabel: maximumTemperatureLabel,
            lowLabel: lowLabel,
            highLabel: highLabel,
            currentHumidityLabel: currentHumidityLabel,
            maskView: maskView
        )
    }
    
    func start(components: CurrentInfoComponents, disposedBy: DisposeBag) -> Void {
        components.locationManager.requestWhenInUseAuthorization()
        components.locationManager.distanceFilter = 10
        components.locationManager.startUpdatingLocation()
        
        shouldHideMap(forAuthorizationEvent: components.locationManager.rx.didChangeAuthorization.asObservable())
            .asDriver(onErrorJustReturn: true)
            .drive(components.mapView.rx.isHidden)
            .disposed(by: disposedBy)
        
        components.mapView.rx.didFinishTileRendering
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { _ in self.fadeOut(view: components.maskView, duration: 0.5) })
            .disposed(by: disposedBy)
        
        components.mapView.rx.willMove
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { _ in self.fadeOut(view: components.hud, duration: 0.5) })
            .disposed(by: disposedBy)

        let location: Observable<CLLocation> = components.locationManager.rx.location
            .filterNil()
            .share(replay: 1)
        
        location
            .take(1)
            .map(toCameraPosition)
            .bind(to: components.mapView.rx.cameraToAnimate)
            .disposed(by: disposedBy)
        
        let idleCameraPosition = components.mapView.rx.idleAt.share()
        let idleCameraLocation = idleCameraPosition.map(toLocation).share()
        let placemark = placemarkForLocation(reverseGeocode: CLGeocoder().rx.reverseGeocode)(idleCameraLocation).share()
        
        formatTime(date: currentDate(), withTimeZoneAtPlacemark: placemark, style: .short, locale: Locale.current)
            .asDriver(onErrorJustReturn: "")
            .drive(components.timeLabel.rx.text)
            .disposed(by: disposedBy)
        
        formatDate(date: currentDate(), withTimeZoneAtPlacemark: placemark, style: .full, locale: Locale.current)
            .asDriver(onErrorJustReturn: "")
            .drive(components.dateLabel.rx.text)
            .disposed(by: disposedBy)

        let weather = checkWeather(fetch: components.weatherService.fetchCurrentWeather)(
                idleCameraPosition.map(toLocation), currentDate(), Locale.current.usesMetricSystem)
            .retry(.exponentialDelayed(maxCount: 50, initial: 0.5, multiplier: 1.0), scheduler: MainScheduler.instance)
            .share()
        
        Observable
            .zip(weather, idleCameraPosition)
            .map { _ in true }  // Everything OK
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { ok in
                if (ok) {
                    self.fadeIn(view: components.hud, duration: 0.5)
                }
            })
            .disposed(by: disposedBy)

        uiScheme(fromLocation: idleCameraLocation, date: currentDate().throttle(60, scheduler: MainScheduler.instance))
            .asDriver(onErrorJustReturn: .light)
            .drive(onNext: { self.setStyle($0.style(), forComponents: components) })
            .disposed(by: disposedBy)
        
        summary(forWeather: weather, placemark: placemark)
            .asDriver(onErrorJustReturn: "")
            .drive(components.summaryLabel.rx.text)
            .disposed(by: disposedBy)
        
        weather.map { $0.temperature }
            .map { self.format(temperature: $0) }
            .asDriver(onErrorJustReturn: "")
            .drive(components.currentTemperatureLabel.rx.text)
            .disposed(by: disposedBy)
        
        weather.map { $0.minimumTemperature }
            .map { self.format(temperature: $0) }
            .asDriver(onErrorJustReturn: "")
            .drive(components.minimumTemperatureLabel.rx.text)
            .disposed(by: disposedBy)
        
        weather.map { _ in return "Low" }
            .asDriver(onErrorJustReturn: "")
            .drive(components.lowLabel.rx.text)
            .disposed(by: disposedBy)
        
        weather.map { $0.maximumTemperature }
            .map { self.format(temperature: $0) }
            .asDriver(onErrorJustReturn: "")
            .drive(components.maximumTemperatureLabel.rx.text)
            .disposed(by: disposedBy)
        
        weather.map { _ in return "High" }
            .asDriver(onErrorJustReturn: "")
            .drive(components.highLabel.rx.text)
            .disposed(by: disposedBy)
        
        weather.map { $0.humidity }
            .map { self.format(humidity: $0) }
            .asDriver(onErrorJustReturn: "")
            .drive(components.currentHumidityLabel.rx.text)
            .disposed(by: disposedBy)
    }
    
    func stop(components: CurrentInfoComponents) -> Void {
        fadeIn(view: components.maskView, duration: 0)
        components.locationManager.stopUpdatingLocation()
    }
    
    private func setStyle(_ style: UIStyle, forComponents: CurrentInfoComponents) -> Void {
        forComponents.hud.backgroundColor = style.hudBackgroundColor
        forComponents.timeLabel.textColor = style.textColor
        forComponents.dateLabel.textColor = style.textColor
        forComponents.summaryLabel.textColor = style.textColor
        forComponents.currentTemperatureLabel.textColor = style.textColor
        forComponents.currentHumidityLabel.textColor = style.textColor
        forComponents.minimumTemperatureLabel.textColor = style.textColor
        forComponents.maximumTemperatureLabel.textColor = style.textColor
        forComponents.lowLabel.textColor = style.textColor
        forComponents.highLabel.textColor = style.textColor
        forComponents.mapView.mapStyle = style.mapStyle
        forComponents.maskView.backgroundColor = style.defaultBackgroundColor
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

    func summary(forWeather: Observable<Weather>, placemark: Observable<CLPlacemark>) -> Observable<String> {
        return Observable
            .combineLatest(forWeather, placemark) { (w, p) in
                if let locality = p.locality {
                    return "\(self.format(weatherDescription: w.description)) over \(locality)"
                }
                return "\(self.format(weatherDescription: w.description))"
            }
    }
    
    func format(weatherDescription: String) -> String {
        let description = weatherDescription.capitalized
        if weatherDescription.lowercased() == "clear" {
            return "\(description) Sky"
        }
        return description
    }
    
    func format(temperature: Float) -> String {
        return String(Int(temperature.rounded())) + "°"
    }
    
    func format(humidity: Float) -> String {
        return "\(String(Int((humidity * 100).rounded())))% rh"
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
