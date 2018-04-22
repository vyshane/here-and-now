//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import CoreLocation
import EasyPeasy
import FittableFontLabel
import RxCocoa
import RxSwift
import RxSwiftExt

// The head up display is a transparent overlay that displays the current location, weather
// and date information
class HeadUpDisplayComponent: ViewComponent {
    
    struct Inputs {
        let uiScheme: Driver<UIScheme>
        let date: Observable<Date>
        let placemark: Observable<CLPlacemark>
        let weather: Observable<Weather>
    }
    
    let view = UIView()
    private let disposedBy: DisposeBag
    private let clock: ClockComponent
    private let currentSummaryLabel = FittableFontLabel()
    private let daySummaryLabel = UILabel()
    private let currentTemperatureLabel = UILabel()
    private let lowLabel = UILabel()
    private let minimumTemperatureLabel = UILabel()
    private let highLabel = UILabel()
    private let maximumTemperatureLabel = UILabel()
    private let currentHumidityLabel = UILabel()

    required init(disposedBy: DisposeBag) {
        self.disposedBy = disposedBy
        view.isUserInteractionEnabled = false
        
        clock = ClockComponent(disposedBy: disposedBy)
        view.addSubview(clock.view)
        clock.view.easy.layout(
            Right(8), Bottom(8)
        )
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        view.addSubview(stackView)
        stackView.easy.layout(
            Top(8),
            Left(16),
            Right(16)
        )
        
        currentSummaryLabel.textAlignment = .left
        stackView.addArrangedSubview(currentSummaryLabel)
        // Fill width
        currentSummaryLabel.font = UIFont.systemFont(ofSize: 180, weight: .light)
        currentSummaryLabel.numberOfLines = 1
        currentSummaryLabel.lineBreakMode = .byWordWrapping
        currentSummaryLabel.maxFontSize = 64
        currentSummaryLabel.minFontScale = 0.1
        currentSummaryLabel.autoAdjustFontSize = true

        stackView.setCustomSpacing(8, after: currentSummaryLabel)
        
        let temperatureStackView = UIStackView()
        temperatureStackView.alignment = .center
        temperatureStackView.spacing = 16
        stackView.addArrangedSubview(temperatureStackView)

        currentTemperatureLabel.textAlignment = .left
        temperatureStackView.addArrangedSubview(currentTemperatureLabel)
        currentTemperatureLabel.font = UIFont.systemFont(ofSize: 90, weight: .thin)
        currentTemperatureLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        minimumTemperatureLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        minimumTemperatureLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        temperatureStackView.addArrangedSubview(minimumTemperatureLabel)

        lowLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        lowLabel.text = "Low"
        view.addSubview(lowLabel)
        lowLabel.easy.layout(
            Left(16).to(currentTemperatureLabel),
            Top().to(minimumTemperatureLabel)
        )

        maximumTemperatureLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        temperatureStackView.addArrangedSubview(maximumTemperatureLabel)
        maximumTemperatureLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)

        highLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        highLabel.text = "High"
        view.addSubview(highLabel)
        highLabel.easy.layout(
            Left(16).to(minimumTemperatureLabel),
            Top().to(maximumTemperatureLabel)
        )

        currentHumidityLabel.textAlignment = .left
        stackView.addArrangedSubview(currentHumidityLabel)
        currentHumidityLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        
        daySummaryLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        daySummaryLabel.numberOfLines = 0
        currentSummaryLabel.lineBreakMode = .byWordWrapping
        stackView.addArrangedSubview(daySummaryLabel)
    }
    
    func start(_ inputs: Inputs) {
        clock.start(
            ClockComponent.Inputs(
                uiScheme: inputs.uiScheme,
                date: inputs.date,
                timeZone: inputs.placemark
                    .map { $0.timeZone }
                    .filterNil()
            )
        )
        
        inputs.uiScheme
            .map { $0.style() }
            .drive(onNext: {
                self.view.backgroundColor = $0.hudBackgroundColor
                self.currentSummaryLabel.textColor = $0.textColor
                self.currentSummaryLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.daySummaryLabel.textColor = $0.textColor
                self.daySummaryLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.lowLabel.textColor = $0.textColor
                self.lowLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.minimumTemperatureLabel.textColor = $0.textColor
                self.minimumTemperatureLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.highLabel.textColor = $0.textColor
                self.highLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.maximumTemperatureLabel.textColor = $0.textColor
                self.maximumTemperatureLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.currentHumidityLabel.textColor = $0.textColor
                self.currentHumidityLabel.outlineShadow(color: $0.defaultBackgroundColor)
            })
            .disposed(by: disposedBy)
        
        currentSummary(forWeather: inputs.weather, placemark: inputs.placemark)
            .drive(currentSummaryLabel.rx.text)
            .disposed(by: disposedBy)
        
        temperatureColor(forWeather: inputs.weather, uiScheme: inputs.uiScheme)
            .drive(onNext: {
                self.currentTemperatureLabel.textColor = $0
                self.currentHumidityLabel.textColor = $0
            })
            .disposed(by: disposedBy)

        inputs.weather.map { $0.temperature }
            .map { WeatherFormatter.format(temperature: $0) }
            .asDriver(onErrorJustReturn: "")
            .drive(self.currentTemperatureLabel.rx.text)
            .disposed(by: disposedBy)
        
        inputs.weather.map { $0.minimumTemperature }
            .map { WeatherFormatter.format(temperature: $0) }
            .asDriver(onErrorJustReturn: "")
            .drive(self.minimumTemperatureLabel.rx.text)
            .disposed(by: disposedBy)
        
        inputs.weather.map { $0.maximumTemperature }
            .map { WeatherFormatter.format(temperature: $0) }
            .asDriver(onErrorJustReturn: "")
            .drive(self.maximumTemperatureLabel.rx.text)
            .disposed(by: disposedBy)
        
        inputs.weather.map { $0.humidity }
            .map { WeatherFormatter.format(humidity: $0) }
            .asDriver(onErrorJustReturn: "")
            .drive(self.currentHumidityLabel.rx.text)
            .disposed(by: disposedBy)
        
        inputs.weather.map { $0.daySummary }
            .asDriver(onErrorJustReturn: "")
            .drive(self.daySummaryLabel.rx.text)
            .disposed(by: disposedBy)
    }
}

extension HeadUpDisplayComponent {
    func currentSummary(forWeather: Observable<Weather>, placemark: Observable<CLPlacemark>) -> Driver<String> {
        return Observable
            .combineLatest(forWeather, placemark) { (w, p) in
                if let locality = p.locality {
                    return "\(WeatherFormatter.format(currentSummary: w.currentSummary)) over \(locality)"
                }
                return "\(WeatherFormatter.format(currentSummary: w.currentSummary))"
            }
            .asDriver(onErrorJustReturn: "")
    }
    
    func temperatureColor(forWeather: Observable<Weather>, uiScheme: Driver<UIScheme>) -> Driver<UIColor> {
        return Observable
            .combineLatest(forWeather, uiScheme.asObservable()) { (w, s) in
                if w.apparentTemperature < 10 {
                    return s.style().temperatureColor.cold
                }
                if w.apparentTemperature >= 10 && w.apparentTemperature < 15 {
                    return s.style().temperatureColor.cool
                }
                if w.apparentTemperature >= 15 && w.apparentTemperature < 20 {
                    return s.style().temperatureColor.warm
                }
                if w.apparentTemperature >= 20 && w.apparentTemperature < 25 {
                    return s.style().temperatureColor.warmer
                }
                if w.apparentTemperature >= 25 && w.apparentTemperature < 30 {
                    return s.style().temperatureColor.warmerToHot
                }
                if w.apparentTemperature >= 30 && w.apparentTemperature < 37 {
                    return s.style().temperatureColor.hot
                }
                return s.style().temperatureColor.veryHot
        }
        .asDriver(onErrorJustReturn: .clear)
    }
}
