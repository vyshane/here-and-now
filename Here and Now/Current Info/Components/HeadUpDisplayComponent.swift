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
    private let currentTemperatureLabel = UILabel()
    private let lowLabel = UILabel()
    private let minimumTemperatureLabel = UILabel()
    private let highLabel = UILabel()
    private let maximumTemperatureLabel = UILabel()
    private let precipitationTypeLabel = UILabel()
    private let precipitationProbabilityLabel = UILabel()
    private let currentHumidityLabel = UILabel()
    private let daySummaryLabel = UILabel()
    private let localTimeLabel = UILabel()

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

        let statsStackView = UIStackView()
        statsStackView.alignment = .center
        statsStackView.spacing = 12
        stackView.addArrangedSubview(statsStackView)

        currentTemperatureLabel.textAlignment = .left
        statsStackView.addArrangedSubview(currentTemperatureLabel)
        currentTemperatureLabel.font = UIFont.systemFont(ofSize: 76, weight: .thin)
        currentTemperatureLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        minimumTemperatureLabel.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        minimumTemperatureLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        statsStackView.addArrangedSubview(minimumTemperatureLabel)

        lowLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        lowLabel.text = "Low"
        view.addSubview(lowLabel)
        lowLabel.easy.layout(
            Left(12).to(currentTemperatureLabel),
            Top().to(minimumTemperatureLabel)
        )

        maximumTemperatureLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        statsStackView.addArrangedSubview(maximumTemperatureLabel)
        maximumTemperatureLabel.font = UIFont.systemFont(ofSize: 22, weight: .medium)

        highLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        highLabel.text = "High"
        view.addSubview(highLabel)
        highLabel.easy.layout(
            Left(12).to(minimumTemperatureLabel),
            Top().to(maximumTemperatureLabel)
        )
        
        precipitationProbabilityLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        statsStackView.addArrangedSubview(precipitationProbabilityLabel)
        precipitationProbabilityLabel.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        
        precipitationTypeLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        view.addSubview(precipitationTypeLabel)
        precipitationTypeLabel.easy.layout(
            Left(12).to(maximumTemperatureLabel),
            Top().to(precipitationProbabilityLabel)
        )

        currentHumidityLabel.textAlignment = .left
        stackView.addArrangedSubview(currentHumidityLabel)
        currentHumidityLabel.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        stackView.setCustomSpacing(4, after: currentHumidityLabel)

        daySummaryLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        daySummaryLabel.numberOfLines = 0
        stackView.addArrangedSubview(daySummaryLabel)

        localTimeLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        localTimeLabel.numberOfLines = 0
        stackView.addArrangedSubview(localTimeLabel)
    }
    
    func start(_ inputs: Inputs) {
        clock.start(
            ClockComponent.Inputs(
                uiScheme: inputs.uiScheme,
                date: inputs.date,
                timeZone: inputs.placemark.map{ $0.timeZone }.filterNil()
            )
        )
        
        inputs.uiScheme
            .map { $0.style() }
            .drive(onNext: {
                self.view.backgroundColor = $0.hudBackgroundColor
                self.currentSummaryLabel.textColor = $0.textColor
                self.currentSummaryLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.lowLabel.textColor = $0.textColor
                self.lowLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.minimumTemperatureLabel.textColor = $0.textColor
                self.minimumTemperatureLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.highLabel.textColor = $0.textColor
                self.highLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.maximumTemperatureLabel.textColor = $0.textColor
                self.maximumTemperatureLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.precipitationTypeLabel.textColor = $0.textColor
                self.precipitationTypeLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.precipitationProbabilityLabel.textColor = $0.textColor
                self.precipitationProbabilityLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.currentHumidityLabel.textColor = $0.textColor
                self.currentHumidityLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.daySummaryLabel.textColor = $0.textColor
                self.daySummaryLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.localTimeLabel.textColor = $0.textColor
                self.localTimeLabel.outlineShadow(color: $0.defaultBackgroundColor)
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
        
        inputs.weather.map { $0.precipitationProbability }
            .map { WeatherFormatter.format(precipitationProbability: $0) }
            .asDriver(onErrorJustReturn: "")
            .drive(self.precipitationProbabilityLabel.rx.text)
            .disposed(by: disposedBy)
        
        inputs.weather.map { $0.precipitationType }
            .map { WeatherFormatter.format(precipitationType: $0) }
            .asDriver(onErrorJustReturn: "")
            .drive(self.precipitationTypeLabel.rx.text)
            .disposed(by: disposedBy)
        
        inputs.weather.map { $0.daySummary }
            .map { WeatherFormatter.format(daySummary: $0) }
            .asDriver(onErrorJustReturn: "")
            .drive(self.daySummaryLabel.rx.text)
            .disposed(by: disposedBy)
        
        formatLocalTime(date: inputs.date, withPlacemark: inputs.placemark, locale: Locale.current)
            .drive(self.localTimeLabel.rx.text)
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
                var apparentTemperature = w.apparentTemperature
                if !w.metricSystemUnits {
                    apparentTemperature = (w.apparentTemperature - 32) * 5 / 9
                }
                var temperatureColor: UIColor
                if apparentTemperature < 10 {
                    temperatureColor = s.style().temperatureColor.cold
                } else if apparentTemperature >= 10 && apparentTemperature < 15 {
                    temperatureColor = s.style().temperatureColor.cool
                } else  if apparentTemperature >= 15 && apparentTemperature < 20 {
                    temperatureColor = s.style().temperatureColor.warm
                } else if apparentTemperature >= 20 && apparentTemperature < 25 {
                    temperatureColor = s.style().temperatureColor.warmer
                } else if apparentTemperature >= 25 && apparentTemperature < 30 {
                    temperatureColor = s.style().temperatureColor.warmerToHot
                } else if apparentTemperature >= 30 && apparentTemperature < 37 {
                    temperatureColor = s.style().temperatureColor.hot
                } else {
                    temperatureColor = s.style().temperatureColor.veryHot
                }
                // If we desaturate the color, also darken or lighten it to ensure that text remains legible
                if s == .light {
                    temperatureColor = temperatureColor.darken(by: w.cloudCover * 0.5)
                } else {
                    temperatureColor = temperatureColor.lighten(by: w.cloudCover * 0.5)
                }
                return temperatureColor.desaturate(by: w.cloudCover * 0.5)
        }
        .asDriver(onErrorJustReturn: .clear)
    }
    
    func formatLocalTime(date: Observable<Date>, withPlacemark: Observable<CLPlacemark>,
                         locale: Locale) -> Driver<String> {
        return Observable
            .combineLatest(date, withPlacemark)
            .map {
                let timeFormatter = DateFormatter()
                timeFormatter.timeZone = $0.1.timeZone
                timeFormatter.locale = locale
                timeFormatter.timeStyle = .short
                let time = timeFormatter.string(from: $0.0)
                
                let dayformatter = DateFormatter()
                dayformatter.dateFormat = "EEEE"
                dayformatter.timeZone = $0.1.timeZone
                dayformatter.locale = locale
                let day = dayformatter.string(from: $0.0)
                
                return "It is \(day) \(time)"
            }
            .asDriver(onErrorJustReturn: "")
    }
}
