//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import UIKit

public extension UIColor {
    
    public func desaturate(by: Float) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            s = s - (s * CGFloat(by))
            s = max(min(s, 1.0), 0.0)
            return UIColor(hue: h, saturation: s, brightness: b, alpha: a)
        }
        return self
    }
    
    public func darken(by: Float) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            b = b - (b * CGFloat(by))
            b = max(min(s, 1.0), 0.0)
            return UIColor(hue: h, saturation: s, brightness: b, alpha: a)
        }
        return self
    }
    
    public func lighten(by: Float) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            b = b + (s * CGFloat(by))
            b = max(min(b, 1.0), 0.0)
            return UIColor(hue: h, saturation: s, brightness: b, alpha: a)
        }
        return self
    }
}
