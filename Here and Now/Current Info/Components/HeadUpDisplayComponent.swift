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
    private let timeAndLocationLabel = FittableFontLabel()
    private let currentTemperatureLabel = UILabel()
    private let lowLabel = UILabel()
    private let minimumTemperatureLabel = UILabel()
    private let highLabel = UILabel()
    private let maximumTemperatureLabel = UILabel()
    private let humidityLabel = UILabel()
    private let currentHumidityLabel = UILabel()
    private let currentWeatherSummaryLabel = UILabel()
    private let daySummaryLabel = UILabel()
    private let precipitationLabel = UILabel()

    required init(disposedBy: DisposeBag) {
        self.disposedBy = disposedBy
        view.isUserInteractionEnabled = false
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        view.addSubview(stackView)
        stackView.easy.layout(
            Top(8),
            Left(16),
            Right(16)
        )
        
        timeAndLocationLabel.textAlignment = .left
        stackView.addArrangedSubview(timeAndLocationLabel)
        // Fill width
        timeAndLocationLabel.font = UIFont.systemFont(ofSize: 180, weight: .thin)
        timeAndLocationLabel.numberOfLines = 1
        timeAndLocationLabel.lineBreakMode = .byWordWrapping
        timeAndLocationLabel.maxFontSize = 64
        timeAndLocationLabel.minFontScale = 0.1
        timeAndLocationLabel.autoAdjustFontSize = true

        let statsStackView = UIStackView()
        statsStackView.alignment = .center
        statsStackView.spacing = 12
        stackView.addArrangedSubview(statsStackView)

        currentTemperatureLabel.textAlignment = .left
        statsStackView.addArrangedSubview(currentTemperatureLabel)
        currentTemperatureLabel.font = UIFont.systemFont(ofSize: 52, weight: .thin)
        currentTemperatureLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let lowStackView = UIStackView()
        lowStackView.axis = .vertical
        statsStackView.addArrangedSubview(lowStackView)
        
        minimumTemperatureLabel.font = UIFont.systemFont(ofSize: 22, weight: .regular)
        minimumTemperatureLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        lowStackView.addArrangedSubview(minimumTemperatureLabel)

        lowLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        lowLabel.text = "Low"
        lowStackView.addArrangedSubview(lowLabel)

        let highStackView = UIStackView()
        highStackView.axis = .vertical
        statsStackView.addArrangedSubview(highStackView)
        
        maximumTemperatureLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        highStackView.addArrangedSubview(maximumTemperatureLabel)
        maximumTemperatureLabel.font = UIFont.systemFont(ofSize: 22, weight: .regular)

        highLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        highLabel.text = "High"
        highStackView.addArrangedSubview(highLabel)

        let humidityStackView = UIStackView()
        humidityStackView.axis = .vertical
        statsStackView.addArrangedSubview(humidityStackView)
        
        currentHumidityLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        humidityStackView.addArrangedSubview(currentHumidityLabel)
        currentHumidityLabel.font = UIFont.systemFont(ofSize: 22, weight: .regular)
        
        humidityLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        humidityLabel.text = "Humidity"
        humidityStackView.addArrangedSubview(humidityLabel)

        currentWeatherSummaryLabel.textAlignment = .left
        stackView.addArrangedSubview(currentWeatherSummaryLabel)
        currentWeatherSummaryLabel.font = UIFont.systemFont(ofSize: 22, weight: .regular)

        daySummaryLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        daySummaryLabel.numberOfLines = 0
        stackView.addArrangedSubview(daySummaryLabel)

        precipitationLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        precipitationLabel.numberOfLines = 0
        stackView.addArrangedSubview(precipitationLabel)
    }
    
    func start(_ inputs: Inputs) {
        inputs.uiScheme
            .map { $0.style() }
            .drive(onNext: {
                self.view.backgroundColor = $0.hudBackgroundColor
                
                self.timeAndLocationLabel.textColor = $0.textColor
                self.timeAndLocationLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.timeAndLocationLabel.font = $0.mainHeadingFont
                
                self.currentTemperatureLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.currentTemperatureLabel.font = $0.mainStatFont
                
                self.lowLabel.textColor = $0.textColor
                self.lowLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.lowLabel.font = $0.subStatLabelFont
                
                self.minimumTemperatureLabel.textColor = $0.textColor
                self.minimumTemperatureLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.minimumTemperatureLabel.font = $0.subStatFont
                
                self.highLabel.textColor = $0.textColor
                self.highLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.highLabel.font = $0.subStatLabelFont
                
                self.maximumTemperatureLabel.textColor = $0.textColor
                self.maximumTemperatureLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.maximumTemperatureLabel.font = $0.subStatFont
                
                self.currentHumidityLabel.textColor = $0.textColor
                self.currentHumidityLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.currentHumidityLabel.font = $0.subStatFont
                
                self.humidityLabel.textColor = $0.textColor
                self.humidityLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.humidityLabel.font = $0.subStatLabelFont
                
                self.currentWeatherSummaryLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.currentWeatherSummaryLabel.font = $0.currentWeatherFont
                
                self.daySummaryLabel.textColor = $0.textColor
                self.daySummaryLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.daySummaryLabel.font = $0.normalTextFont
                
                self.precipitationLabel.textColor = $0.textColor
                self.precipitationLabel.outlineShadow(color: $0.defaultBackgroundColor)
                self.precipitationLabel.font = $0.normalTextFont
            })
            .disposed(by: disposedBy)
        
        formatTime(inputs.date, place: inputs.placemark, locale: Locale.current)
            .drive(timeAndLocationLabel.rx.text)
            .disposed(by: disposedBy)
        
        temperatureColor(forWeather: inputs.weather, uiScheme: inputs.uiScheme)
            .drive(onNext: {
                self.currentTemperatureLabel.textColor = $0
                self.currentWeatherSummaryLabel.textColor = $0
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
        
        inputs.weather.map { $0.currentSummary }
            .map { WeatherFormatter.format(currentSummary: $0) }
            .asDriver(onErrorJustReturn: "")
            .drive(self.currentWeatherSummaryLabel.rx.text)
            .disposed(by: disposedBy)
        
        inputs.weather.map { $0.humidity }
            .map { WeatherFormatter.format(humidity: $0) }
            .asDriver(onErrorJustReturn: "")
            .drive(self.currentHumidityLabel.rx.text)
            .disposed(by: disposedBy)
        
        inputs.weather.map { $0.daySummary }
            .map { WeatherFormatter.format(daySummary: $0) }
            .asDriver(onErrorJustReturn: "")
            .drive(self.daySummaryLabel.rx.text)
            .disposed(by: disposedBy)
        
        inputs.weather.map {
                WeatherFormatter.format(precipitationProbability: $0.precipitationProbability,
                                        type: $0.precipitationType)
            }
            .asDriver(onErrorJustReturn: "")
            .drive(self.precipitationLabel.rx.text)
            .disposed(by: disposedBy)
    }
}

extension HeadUpDisplayComponent {
    func formatTime(_ date: Observable<Date>, place: Observable<CLPlacemark>, locale: Locale) -> Driver<String> {
        return Observable
            .combineLatest(date, place) { (d, p) in
                let timeFormatter = DateFormatter()
                timeFormatter.timeZone = p.timeZone
                timeFormatter.locale = locale
                timeFormatter.timeStyle = .short
                let time = timeFormatter.string(from: d)
                if let locality = p.locality {
                    return "\(locality), \(time)"
                }
                return "Local time \(time)"
            }
            .asDriver(onErrorJustReturn: "")
    }
    
    func temperatureColor(forWeather: Observable<Weather>, uiScheme: Driver<UIScheme>) -> Driver<UIColor> {
        return Observable
            .combineLatest(forWeather, uiScheme.asObservable()) { (w, s) in
                var apparentTemperature = w.apparentTemperature
                if !w.metricSystemUnits {
                    let toCelcius: (Float) -> Float = { ($0 - 32) * 5 / 9 }
                    apparentTemperature = toCelcius(w.apparentTemperature)
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
}
