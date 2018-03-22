//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import CoreLocation
import EasyPeasy
import FittableFontLabel
import GoogleMaps
import RxCoreLocation
import RxGoogleMaps
import RxSwift
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
            summaryLabel.font = UIFont.systemFont(ofSize: 180, weight: .thin)
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
            currentHumidityLabel.font = UIFont.systemFont(ofSize: 60, weight: .thin)
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
        
        uiScheme(forLocation: location, date: currentDate())
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                components.timeLabel.textColor = $0.style().textColor
                components.dateLabel.textColor = $0.style().textColor
                components.summaryLabel.textColor = $0.style().textColor
                components.currentTemperatureLabel.textColor = $0.style().textColor
                components.currentHumidityLabel.textColor = $0.style().textColor
                components.mapView.mapStyle = $0.style().mapStyle
                components.maskView.backgroundColor = $0.style().defaultBackgroundColor
            })
            .disposed(by: disposedBy)
        
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
        
        hideMaskView(whenLocationReceived: location)
            .subscribe(onNext: { delay in
                if (components.maskView.alpha > 0) {
                    UIView.animate(withDuration: 0.4,
                                   delay: delay,
                                   options: .curveEaseOut,
                                   animations: { components.maskView.alpha = 0.0 })
                }
            })
            .disposed(by: disposedBy)
        
        mapCameraPosition(forLocation: location)
            .bind(to: components.mapView.rx.cameraToAnimate)
            .disposed(by: disposedBy)
        
        let weather = currentWeather(fetch:
            components.weatherService.fetchCurrentWeather)(location, currentDate(), Locale.current.usesMetricSystem)
            .retry(2)
            .share()
        
        summary(forWeather: weather)
            .asDriver(onErrorJustReturn: "")
            .drive(components.summaryLabel.rx.text)
            .disposed(by: disposedBy)
        
        weather.map { $0.temperature }
            .map { self.formatTemperature($0) }
            .asDriver(onErrorJustReturn: "")
            .drive(components.currentTemperatureLabel.rx.text)
            .disposed(by: disposedBy)
        
        weather.map { $0.humidity }
            .map { self.formatHumidity($0) }
            .asDriver(onErrorJustReturn: "")
            .drive(components.currentHumidityLabel.rx.text)
            .disposed(by: disposedBy)
    }
    
    func stop(components: CurrentInfoComponents) -> Void {
        components.maskView.alpha = 1.0
        components.locationManager.stopUpdatingLocation()
    }
    
    // MARK: UI State Changes
    
    func uiScheme(forLocation: Observable<CLLocation>, date: Observable<Date>) -> Observable<UIScheme> {
        return Observable.zip(forLocation, date) { (l, d) in
            if let isDayTime = isDaytime(date: d, coordinate: l.coordinate) {
                return isDayTime ? .light : .dark
            }
            return .light
        }
    }
    
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
    
    func hideMaskView(whenLocationReceived: Observable<CLLocation>) -> Observable<Delay> {
        return whenLocationReceived.map { _ in 1.0 }
    }
    
    func mapCameraPosition(forLocation: Observable<CLLocation>) -> Observable<GMSCameraPosition> {
        return forLocation.map { GMSCameraPosition.camera(withTarget: $0.coordinate, zoom: 14) }
    }

    typealias WeatherFetcher = (CLLocationCoordinate2D, Bool) -> Single<Weather>
    
    func currentWeather(fetch: @escaping WeatherFetcher)
        -> (_ location: Observable<CLLocation>, _ date: Observable<Date> , _ useMetricSystem: Bool)
        -> Observable<Weather> {
        return { (location, date, useMetricSystem) in
            return Observable
                .combineLatest(location, date)
                .distinctUntilChanged { (a , b) in
                    let fiveMinutes: TimeInterval = 5 * 60
                    return a.0.distance(from: b.0) < 20 && b.1.timeIntervalSince(a.1) < fiveMinutes
                }
                .map { $0.0 }
                .flatMapLatest { fetch($0.coordinate, useMetricSystem) }
        }
    }
    
    func capitalizeFirst(_ string: String) -> String {
        return string.prefix(1).uppercased() + string.dropFirst()
    }
    
    func summary(forWeather: Observable<Weather>) -> Observable<String> {
        let capitalizeFirst: (_ string: String) -> String = { $0.prefix(1).uppercased() + $0.dropFirst() }
        return forWeather.map { "\(capitalizeFirst($0.description)) over \($0.placeName)" }
    }
    
    func formatTemperature(_ temperature: Float) -> String {
        return String(Int(temperature.rounded())) + "°"
    }
    
    func formatHumidity(_ humidity: Int) -> String {
        return "\(String(humidity))% hu"
    }
}
