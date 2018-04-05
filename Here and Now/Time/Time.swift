//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import CoreLocation
import Foundation
import RxSwift
import Solar

typealias CurrentDate = () -> Observable<Date>

func currentDate() -> Observable<Date> {
    return Observable<NSInteger>
        .interval(0.1, scheduler: MainScheduler.instance)
        .map { _ in Date() }
}

func isDaytime(date: Date, coordinate: CLLocationCoordinate2D) -> Bool? {
    let solar = Solar(for: date, coordinate: coordinate)
    return solar?.isDaytime
}

func isNighttime(date: Date, coordinate: CLLocationCoordinate2D) -> Bool? {
    let solar = Solar(for: date, coordinate: coordinate)
    return solar?.isNighttime
}

func formatTime(date: Observable<Date>, withTimeZoneAtPlacemark: Observable<CLPlacemark>,
                style: DateFormatter.Style, locale: Locale) -> Observable<String> {
    return Observable
        .combineLatest(date, withTimeZoneAtPlacemark)
        .map {
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = $0.1.timeZone
            dateFormatter.locale = locale
            dateFormatter.timeStyle = style
            dateFormatter.dateStyle = .none
            return dateFormatter.string(from: $0.0)
    }
}

func formatDate(date: Observable<Date>, withTimeZoneAtPlacemark: Observable<CLPlacemark>,
                style: DateFormatter.Style, locale: Locale) -> Observable<String> {
    return Observable
        .combineLatest(date, withTimeZoneAtPlacemark)
        .map {
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = $0.1.timeZone
            dateFormatter.locale = locale
            dateFormatter.dateStyle = style
            dateFormatter.timeStyle = .none
            return dateFormatter.string(from: $0.0)
    }
}
