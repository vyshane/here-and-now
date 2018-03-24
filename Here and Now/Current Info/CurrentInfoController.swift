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
        
        let stackView: UIStackView = {
            let stackView = UIStackView()
            stackView.axis = .vertical
            addToRootView.addSubview(stackView)
            stackView.easy.layout(
                Top(8),
                Left(16),
                Right(16)
            )
            return stackView
        }()
        
        let summaryLabel: UILabel = {
            let summaryLabel = FittableFontLabel()
            summaryLabel.textAlignment = .center
            stackView.addArrangedSubview(summaryLabel)
            // Fill width
            summaryLabel.font = UIFont.systemFont(ofSize: 180, weight: .light)
            summaryLabel.numberOfLines = 1
            summaryLabel.lineBreakMode = .byWordWrapping
            summaryLabel.maxFontSize = 180
            summaryLabel.minFontScale = 0.1
            summaryLabel.autoAdjustFontSize = true
            return summaryLabel
        }()
        
        stackView.setCustomSpacing(8, after: summaryLabel)
        
        let currentTemperatureLabel: UILabel = {
            let currentTemperatureLabel = UILabel()
            currentTemperatureLabel.textAlignment = .left
            stackView.addArrangedSubview(currentTemperatureLabel)
            currentTemperatureLabel.font = UIFont.systemFont(ofSize: 130, weight: .thin)
            return currentTemperatureLabel
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
            addToRootView.addSubview(dateLabel)
            dateLabel.easy.layout(
                Right(8), Bottom(8)
            )
            dateLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)  // San Fransisco
            return dateLabel
        }()
        
        let timeLabel: UILabel = {
            let timeLabel = FittableFontLabel()
            timeLabel.textAlignment = .center
            addToRootView.addSubview(timeLabel)
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
            weatherService: WeatherService(apiKey: Config().openWeatherMapAPIKey),
            mapView: mapView,
            timeLabel: timeLabel,
            dateLabel: dateLabel,
            summaryLabel: summaryLabel,
            currentTemperatureLabel: currentTemperatureLabel,
            currentHumidityLabel: currentHumidityLabel,
            maskView: maskView
        )
    }
    
    func start(components: CurrentInfoComponents, disposedBy: DisposeBag) -> Void {
        components.locationManager.requestWhenInUseAuthorization()
        components.locationManager.distanceFilter = 10
        components.locationManager.startUpdatingLocation()
        
        let location: Observable<CLLocation> = components.locationManager.rx.location
            .skipWhile { $0 == nil }
            .map { $0! }
            .share(replay: 1)
        
        formatCurrentTime(fromDate: currentDate(), locale: Locale.current)
            .asDriver(onErrorJustReturn: "")
            .drive(components.timeLabel.rx.text)
            .disposed(by: disposedBy)
        
        formatCurrentDate(fromDate: currentDate(), locale: Locale.current)
            .asDriver(onErrorJustReturn: "")
            .drive(components.dateLabel.rx.text)
            .disposed(by: disposedBy)
        
        shouldHideMap(forAuthorizationEvent: components.locationManager.rx.didChangeAuthorization.asObservable())
            .asDriver(onErrorJustReturn: true)
            .drive(components.mapView.rx.isHidden)
            .disposed(by: disposedBy)
        
        components.mapView.rx.didFinishTileRendering
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { Void in
                if (components.maskView.alpha > 0) {
                    UIView.animate(withDuration: 0.3,
                                   delay: 0,
                                   options: .curveEaseOut,
                                   animations: { components.maskView.alpha = 0.0 })
                }
            })
            .disposed(by: disposedBy)

        mapCameraPosition(forLocation: location)
            .bind(to: components.mapView.rx.cameraToAnimate)
            .disposed(by: disposedBy)
        
        let weather = checkWeather(fetch:
            components.weatherService.fetchCurrentWeather)(location, currentDate(), Locale.current.usesMetricSystem)
            .retry(.exponentialDelayed(maxCount: 50, initial: 0.5, multiplier: 1.0), scheduler: MainScheduler.instance)
            .share()
        
        // Less accurate; use once to initialize scheme
        uiScheme(fromLocation: location, date: currentDate().take(1))
            .asDriver(onErrorJustReturn: .light)
            .drive(onNext: { self.setStyle($0.style(), forComponents: components) })
            .disposed(by: disposedBy)
        
        // More accurate; use periodically to update scheme
        uiScheme(fromWeather: weather, date: currentDate().throttle(30, scheduler: MainScheduler.instance))
            .asDriver(onErrorJustReturn: .light)
            .drive(onNext: { self.setStyle($0.style(), forComponents: components) })
            .disposed(by: disposedBy)
        
        summary(forWeather: weather)
            .asDriver(onErrorJustReturn: "")
            .drive(components.summaryLabel.rx.text)
            .disposed(by: disposedBy)
        
        weather.map { $0.temperature }
            .map { self.format(temperature: $0) }
            .asDriver(onErrorJustReturn: "")
            .drive(components.currentTemperatureLabel.rx.text)
            .disposed(by: disposedBy)
        
        weather.map { $0.humidity }
            .map { self.format(humidity: $0) }
            .asDriver(onErrorJustReturn: "")
            .drive(components.currentHumidityLabel.rx.text)
            .disposed(by: disposedBy)
    }
    
    func stop(components: CurrentInfoComponents) -> Void {
        components.maskView.alpha = 1.0
        components.locationManager.stopUpdatingLocation()
    }
    
    private func setStyle(_ style: UIStyle, forComponents: CurrentInfoComponents) -> Void {
        forComponents.timeLabel.textColor = style.textColor
        forComponents.dateLabel.textColor = style.textColor
        forComponents.summaryLabel.textColor = style.textColor
        forComponents.currentTemperatureLabel.textColor = style.textColor
        forComponents.currentHumidityLabel.textColor = style.textColor
        forComponents.mapView.mapStyle = style.mapStyle
        forComponents.maskView.backgroundColor = style.defaultBackgroundColor
    }
    
    // MARK: UI State Changes

    func formatCurrentTime(fromDate: Observable<Date>, locale: Locale) -> Observable<String> {
        return fromDate.map {
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .short
            dateFormatter.dateStyle = .none
            return dateFormatter.string(from: $0)
        }
    }
    
    func formatCurrentDate(fromDate: Observable<Date>, locale: Locale) -> Observable<String> {
        return fromDate.map {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .full
            dateFormatter.timeStyle = .none
            return dateFormatter.string(from: $0)
        }
    }
    
    func shouldHideMap(forAuthorizationEvent: Observable<CLAuthorizationEvent>) -> Observable<Bool> {
        return forAuthorizationEvent.map {
            switch ($0.status) {
            case .denied: return true
            case _: return false
            }
        }
    }
    
    typealias Delay = TimeInterval

    func mapCameraPosition(forLocation: Observable<CLLocation>) -> Observable<GMSCameraPosition> {
        return forLocation.map { GMSCameraPosition.camera(withTarget: $0.coordinate, zoom: 14) }
    }

    typealias WeatherFetcher = (CLLocationCoordinate2D, Bool) -> Single<Weather>
    
    func checkWeather(fetch: @escaping WeatherFetcher)
        -> (Observable<CLLocation>, Observable<Date>, Bool)
        -> Observable<Weather> {
        return { (location, date, useMetricSystem) in
            Observable
                .combineLatest(location, date)
                .distinctUntilChanged { (a , b) in
                    let fiveMinutes: TimeInterval = 5 * 60
                    return a.0.distance(from: b.0) < 20 && b.1.timeIntervalSince(a.1) < fiveMinutes
                }
                .map { $0.0 }
                .flatMapLatest { fetch($0.coordinate, useMetricSystem) }
        }
    }
    
    func summary(forWeather: Observable<Weather>) -> Observable<String> {
        let capitalizeFirst: (String) -> String = { $0.prefix(1).uppercased() + $0.dropFirst() }
        return forWeather.map { "\(capitalizeFirst($0.description)) over \($0.placeName)" }
    }
    
    func format(temperature: Float) -> String {
        return String(Int(temperature.rounded())) + "°"
    }
    
    func format(humidity: Int) -> String {
        return "\(String(humidity))% hu"
    }
}
