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
    
    func initComponents(addToRootView: UIView, disposedBy: DisposeBag) -> CurrentInfoComponents {
        
        let map = Map(disposedBy: disposedBy)
        addToRootView.addSubview(map.view)
        map.view.easy.layout(Edges())

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
        
        fadeOut(view: hud, duration: 0)
        
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
            lowLabel.text = "Low"
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
            highLabel.text = "High"
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
            map: map,
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
        
        let mapSources = components.map.start(
            Map.Sinks(
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
            .drive(onNext: { _ in self.fadeOut(view: components.hud, duration: 0.5) })
            .disposed(by: disposedBy)
        
        let idleCameraPosition = mapSources.idleAt.share()
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
        
        shouldShowHud(whenWeatherFetched: weather, mapCameraIdleAt: idleCameraPosition)
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
            .map { WeatherFormatter.format(temperature: $0) }
            .asDriver(onErrorJustReturn: "")
            .drive(components.currentTemperatureLabel.rx.text)
            .disposed(by: disposedBy)
        
        weather.map { $0.minimumTemperature }
            .map { WeatherFormatter.format(temperature: $0) }
            .asDriver(onErrorJustReturn: "")
            .drive(components.minimumTemperatureLabel.rx.text)
            .disposed(by: disposedBy)
        
        weather.map { $0.maximumTemperature }
            .map { WeatherFormatter.format(temperature: $0) }
            .asDriver(onErrorJustReturn: "")
            .drive(components.maximumTemperatureLabel.rx.text)
            .disposed(by: disposedBy)
        
        weather.map { $0.humidity }
            .map { WeatherFormatter.format(humidity: $0) }
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
        forComponents.maskView.backgroundColor = style.defaultBackgroundColor
    }
    
    // MARK: UI State Changes

    func shouldShowHud(whenWeatherFetched: Observable<Weather>,
                       mapCameraIdleAt: Observable<GMSCameraPosition>) -> Observable<Bool> {
        return Observable
            .zip(whenWeatherFetched, mapCameraIdleAt)
            .map { _ in true }
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
                    return "\(WeatherFormatter.format(description: w.description)) over \(locality)"
                }
                return "\(WeatherFormatter.format(description: w.description))"
            }
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
