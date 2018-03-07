//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import Foundation
import RxSwift

func currentDate(tickInterval: Double = 0.1) -> Observable<Date> {
    return Observable<NSInteger>
        .interval(tickInterval, scheduler: MainScheduler.instance)
        .map { _ in Date() }
}
