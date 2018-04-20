//
//  UILabel+StyleHelpers.swift
//  Here and Now
//
//  Created by Vy-Shane Xie on 20/4/18.
//  Copyright © 2018 Vy-Shane. All rights reserved.
//

import UIKit

extension UILabel {
    func outlineShadow(color: UIColor) {
        self.layer.masksToBounds = false
        self.layer.shadowColor = color.cgColor
        self.layer.shadowRadius = 1.0
        self.layer.shadowOpacity = 0.6
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
    }
}
