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

func formattedTime(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "hh:mm"
    return dateFormatter.string(from: date)
}

func isDaytime(date: Date, coordinates: CLLocationCoordinate2D) -> Bool? {
    let solar = Solar(for: date, coordinate: coordinates)
    return solar?.isDaytime
}

func isNighttime(date: Date, coordinates: CLLocationCoordinate2D) -> Bool? {
    let solar = Solar(for: date, coordinate: coordinates)
    return solar?.isNighttime
}
