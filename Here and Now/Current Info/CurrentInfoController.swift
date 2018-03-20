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
        
        let stackView: UIStackView = {
            let stackView = UIStackView()
            stackView.axis = .vertical
            addToRootView.addSubview(stackView)
            stackView.easy.layout(
                Top(16),
                Left(8),
                Right(8)
            )
            return stackView
        }()
        
        let timeLabel: UILabel = {
            let timeLabel = UILabel()
            timeLabel.textAlignment = .center
            stackView.addArrangedSubview(timeLabel)
            timeLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)  // San Fransisco
            return timeLabel
        }()
        
        let placeLabel: UILabel = {
            let placeLabel = FittableFontLabel()
            placeLabel.textAlignment = .center
            stackView.addArrangedSubview(placeLabel)
            
            // Fill width
            placeLabel.font = UIFont.systemFont(ofSize: 180, weight: .thin)  // San Fransisco
            placeLabel.numberOfLines = 1
            placeLabel.lineBreakMode = .byWordWrapping
            placeLabel.maxFontSize = 180
            placeLabel.minFontScale = 0.3
            let calculatedFontSize = timeLabel.fontSizeThatFits(text: "00:00", maxFontSize: 180,
                                                                minFontScale: 0.3, rectSize: nil)
            placeLabel.font = UIFont.systemFont(ofSize: calculatedFontSize, weight: .thin)
            return placeLabel
        }()
        
        let weatherDescriptionLabel: UILabel = {
            let weatherDescriptionLabel = UILabel()
            weatherDescriptionLabel.textAlignment = .center
            stackView.addArrangedSubview(weatherDescriptionLabel)
            weatherDescriptionLabel.font = UIFont.systemFont(ofSize: 30, weight: .regular)  // San Fransisco
            return weatherDescriptionLabel
        }()
        
        let currentTemperatureLabel: UILabel = {
            let currentTemperatureLabel = UILabel()
            currentTemperatureLabel.textAlignment = .center
            stackView.addArrangedSubview(currentTemperatureLabel)
            currentTemperatureLabel.font = UIFont.systemFont(ofSize: 70, weight: .regular)  // San Fransisco
            return currentTemperatureLabel
        }()
        
        return Components(
            locationManager: CLLocationManager(),
            weatherService: WeatherService(apiKey: Config().openWeatherMapAPIKey),
            mapView: mapView,
            timeLabel: timeLabel,
            placeLabel: placeLabel,
            weatherDescriptionLabel: weatherDescriptionLabel,
            currentTemperatureLabel: currentTemperatureLabel,
            maskView: maskView
        )
    }
    
    func start(components: Components, disposedBy: DisposeBag) -> Void {
        components.locationManager.requestWhenInUseAuthorization()
        components.locationManager.distanceFilter = 10
        components.locationManager.startUpdatingLocation()
        
        let location = components.locationManager.rx.location.share()
        
        uiScheme(forLocation: location, date: currentDate())
            .subscribe(onNext: {
                components.timeLabel.textColor = $0.style().textColor
                components.placeLabel.textColor = $0.style().textColor
                components.mapView.mapStyle = $0.style().mapStyle
                components.maskView.backgroundColor = $0.style().defaultBackgroundColor
            })
            .disposed(by: disposedBy)
        
        formatCurrentTime(fromDate: currentDate())
            .bind(to: components.timeLabel.rx.text)
            .disposed(by: disposedBy)
        
        shouldHideMap(forAuthorizationEvent: components.locationManager.rx.didChangeAuthorization.asObservable())
            .bind(to: components.mapView.rx.isHidden)
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
        
        let weather = currentWeather(fetch: components.weatherService.fetchCurrentWeather)(location).share()
        
        weather.map { $0.placeName }
            .bind(to: components.placeLabel.rx.text)
            .disposed(by: disposedBy)
        
        weather.map { $0.description }
            .bind(to: components.weatherDescriptionLabel.rx.text)
            .disposed(by: disposedBy)
        
        weather.map { $0.temperature }
            .map { self.formatTemperature($0) }
            .bind(to: components.currentTemperatureLabel.rx.text)
            .disposed(by: disposedBy)
    }
    
    func stop(components: Components) -> Void {
        components.maskView.alpha = 1.0
        components.locationManager.stopUpdatingLocation()
    }
    
    // MARK: UI State Changes
    
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
    
    func formatCurrentTime(fromDate: Observable<Date>) -> Observable<String> {
        return fromDate.map {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "hh:mm"
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
    
    func hideMaskView(whenLocationReceived: Observable<CLLocation?>) -> Observable<Delay> {
        return whenLocationReceived.map { _ in 1.0 }
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
    
    typealias WeatherFetcher = (CLLocationCoordinate2D) -> Single<Weather>
    
    // TODO: Investigate using CLGeocoder to get place name and only fetch weather if the place name changes
    func currentWeather(fetch: @escaping WeatherFetcher) ->
        (_ location: Observable<CLLocation?>) -> Observable<Weather> {
            let fetchWeather: (CLLocation?) -> Observable<Weather> = {
                if let location = $0 {
                    return fetch(location.coordinate).asObservable()
                }
                return Observable.never()
            }
            return { location in
                return location
                    // It's unlikely that we would have travelled far enough that repeatedly
                    // querying the weather service gives us different weather conditions
                    .throttle(60, latest: true, scheduler: MainScheduler())
                    .flatMap { fetchWeather($0) }
            }
    }
    
    func formatTemperature(_ temperature: Float) -> String {
        return String(Int(temperature.rounded())) + "°"
    }
}
