//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import EasyPeasy
import FittableFontLabel
import RxCocoa
import RxSwift

class ClockComponent: ViewComponent {
    
    struct Inputs {
        let uiScheme: Driver<UIScheme>
        let date: Observable<Date>
        let timeZone: Observable<TimeZone>
    }
    
    let view = UIView()
    private let disposedBy: DisposeBag
    private let dateLabel = UILabel()
    private let timeLabel = FittableFontLabel()

    required init(disposedBy: DisposeBag) {
        self.disposedBy = disposedBy

        dateLabel.textAlignment = .center
        view.addSubview(dateLabel)
        dateLabel.easy.layout(
            Bottom(0), Right(0)
        )
        dateLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)

        timeLabel.textAlignment = .center
        view.addSubview(timeLabel)
        timeLabel.easy.layout(
            Width().like(dateLabel), Right(0), Bottom(4).to(dateLabel)
        )
        // Fill width
        timeLabel.font = UIFont.systemFont(ofSize: 180, weight: .regular)
        timeLabel.numberOfLines = 1
        timeLabel.lineBreakMode = .byWordWrapping
        timeLabel.maxFontSize = 180
        timeLabel.minFontScale = 0.1
        timeLabel.autoAdjustFontSize = true
    }

    func start(_ inputs: Inputs) {
        formatTime(date: inputs.date, withTimeZone: inputs.timeZone, style: .short, locale: Locale.current)
            .drive(self.timeLabel.rx.text)
            .disposed(by: disposedBy)
        
        formatDate(date: inputs.date, withTimeZone: inputs.timeZone, style: .full, locale: Locale.current)
            .drive(self.dateLabel.rx.text)
            .disposed(by: disposedBy)
        
        inputs.uiScheme
            .map { $0.style().textColor }
            .drive(onNext: {
                self.timeLabel.textColor = $0
                self.dateLabel.textColor = $0
            })
            .disposed(by: disposedBy)
    }
}

extension ClockComponent {
    func formatTime(date: Observable<Date>, withTimeZone: Observable<TimeZone>,
                    style: DateFormatter.Style, locale: Locale) -> Driver<String> {
        return Observable
            .combineLatest(date, withTimeZone)
            .map {
                let dateFormatter = DateFormatter()
                dateFormatter.timeZone = $0.1
                dateFormatter.locale = locale
                dateFormatter.timeStyle = style
                dateFormatter.dateStyle = .none
                return dateFormatter.string(from: $0.0)
            }
            .asDriver(onErrorJustReturn: "")
    }
    
    func formatDate(date: Observable<Date>, withTimeZone: Observable<TimeZone>,
                    style: DateFormatter.Style, locale: Locale) -> Driver<String> {
        return Observable
            .combineLatest(date, withTimeZone)
            .map {
                let dateFormatter = DateFormatter()
                dateFormatter.timeZone = $0.1
                dateFormatter.locale = locale
                dateFormatter.dateStyle = style
                dateFormatter.timeStyle = .none
                return dateFormatter.string(from: $0.0)
            }
            .asDriver(onErrorJustReturn: "")
    }
}
