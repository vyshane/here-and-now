//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import CoreLocation
import Foundation
import RxSwift
import Solar

func currentDate(tickInterval: Double = 0.1) -> Observable<Date> {
    return Observable<NSInteger>
        .interval(tickInterval, scheduler: MainScheduler.instance)
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
