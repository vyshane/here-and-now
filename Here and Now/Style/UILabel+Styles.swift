//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import UIKit

extension UILabel {
    func outlineShadow(color: UIColor) {
        self.layer.masksToBounds = false
        self.layer.shadowColor = color.cgColor
        self.layer.shadowRadius = 5.0
        self.layer.shadowOpacity = 1.0
        self.layer.shadowOffset = CGSize.zero
    }
}
