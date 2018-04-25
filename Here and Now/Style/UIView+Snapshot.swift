//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import UIKit

extension UIView {
    func snapshot() -> UIImage {
        return UIGraphicsImageRenderer(size: bounds.size).image { _ in
            drawHierarchy(in: CGRect(origin: .zero, size: bounds.size), afterScreenUpdates: true)
        }
    }
}
