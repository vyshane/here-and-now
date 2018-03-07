//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import Foundation
import RxSwift

func currentDate() -> Observable<Date> {
    return Observable<NSInteger>
        .interval(0.1, scheduler: MainScheduler.instance)
        .map { _ in Date() }
}
