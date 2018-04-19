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
    private let summaryLabel = FittableFontLabel()
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
        
        summaryLabel.textAlignment = .left
        stackView.addArrangedSubview(summaryLabel)
        // Fill width
        summaryLabel.font = UIFont.systemFont(ofSize: 180, weight: .light)
        summaryLabel.numberOfLines = 1
        summaryLabel.lineBreakMode = .byWordWrapping
        summaryLabel.maxFontSize = 64
        summaryLabel.minFontScale = 0.1
        summaryLabel.autoAdjustFontSize = true

        stackView.setCustomSpacing(8, after: summaryLabel)
        
        let temperatureStackView = UIStackView()
        temperatureStackView.alignment = .center
        temperatureStackView.spacing = 16
        stackView.addArrangedSubview(temperatureStackView)

        currentTemperatureLabel.textAlignment = .left
        temperatureStackView.addArrangedSubview(currentTemperatureLabel)
        currentTemperatureLabel.font = UIFont.systemFont(ofSize: 130, weight: .thin)
        currentTemperatureLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        minimumTemperatureLabel.font = UIFont.systemFont(ofSize: 28, weight: .regular)
        minimumTemperatureLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        temperatureStackView.addArrangedSubview(minimumTemperatureLabel)

        lowLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        lowLabel.text = "Low"
        view.addSubview(lowLabel)
        lowLabel.easy.layout(
            Left(16).to(currentTemperatureLabel),
            Top().to(minimumTemperatureLabel)
        )

        maximumTemperatureLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        temperatureStackView.addArrangedSubview(maximumTemperatureLabel)
        maximumTemperatureLabel.font = UIFont.systemFont(ofSize: 28, weight: .regular)

        highLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        highLabel.text = "High"
        view.addSubview(highLabel)
        highLabel.easy.layout(
            Left(16).to(minimumTemperatureLabel),
            Top().to(maximumTemperatureLabel)
        )

        currentHumidityLabel.textAlignment = .left
        stackView.addArrangedSubview(currentHumidityLabel)
        currentHumidityLabel.font = UIFont.systemFont(ofSize: 64, weight: .light)
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
            .map { $0.style().textColor }
            .drive(onNext: {
                self.summaryLabel.textColor = $0
                self.currentTemperatureLabel.textColor = $0
                self.lowLabel.textColor = $0
                self.minimumTemperatureLabel.textColor = $0
                self.highLabel.textColor = $0
                self.maximumTemperatureLabel.textColor = $0
                self.currentHumidityLabel.textColor = $0
            })
            .disposed(by: disposedBy)
        
        summary(forWeather: inputs.weather, placemark: inputs.placemark)
            .drive(summaryLabel.rx.text)
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
    }
}

extension HeadUpDisplayComponent {
    func summary(forWeather: Observable<Weather>, placemark: Observable<CLPlacemark>) -> Driver<String> {
        return Observable
            .combineLatest(forWeather, placemark) { (w, p) in
                if let locality = p.locality {
                    return "\(WeatherFormatter.format(description: w.description)) over \(locality)"
                }
                return "\(WeatherFormatter.format(description: w.description))"
            }
            .asDriver(onErrorJustReturn: "")
    }
}
