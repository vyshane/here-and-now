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
