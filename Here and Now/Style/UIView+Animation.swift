//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import UIKit

extension UIView {
    func fadeIn(duration: TimeInterval = 0) -> Void {
        if self.alpha < 1.0 {
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: { self.alpha = 1.0 })
        }
    }
    
    func fadeOut(duration: TimeInterval = 0) -> Void {
        if self.alpha > 0.0 {
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: { self.alpha = 0.0 })
        }
    }
}
