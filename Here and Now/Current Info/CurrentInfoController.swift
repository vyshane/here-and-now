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
            addToRootView.addSubview(lowLabel)
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
            addToRootView.addSubview(highLabel)
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
            weatherService: WeatherService(apiKey: Config().darkSkyApiKey),
            mapView: mapView,
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
        
        uiScheme(fromLocation: location, date: currentDate().throttle(60, scheduler: MainScheduler.instance))
            .asDriver(onErrorJustReturn: .light)
            .drive(onNext: { self.setStyle($0.style(), forComponents: components) })
            .disposed(by: disposedBy)
        
        summary(forWeather: weather, placemark: components.locationManager.rx.placemark)
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
        components.maskView.alpha = 1.0
        components.locationManager.stopUpdatingLocation()
    }
    
    private func setStyle(_ style: UIStyle, forComponents: CurrentInfoComponents) -> Void {
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
    
    func summary(forWeather: Observable<Weather>, placemark: Observable<CLPlacemark>) -> Observable<String> {
        return Observable
            .combineLatest(forWeather, placemark) { (w, p) in
                let capitalizeFirst: (String) -> String = { $0.prefix(1).uppercased() + $0.dropFirst() }
                if let locality = p.locality {
                    return "\(capitalizeFirst(w.description)) over \(locality)"
                }
                return "\(capitalizeFirst(w.description))"
            }
    }
    
    func format(temperature: Float) -> String {
        return String(Int(temperature.rounded())) + "°"
    }
    
    func format(humidity: Float) -> String {
        return "\(String(Int((humidity * 100).rounded())))% rh"
    }
}
