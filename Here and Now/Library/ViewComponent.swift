//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import RxSwift
import UIKit

protocol ViewComponent {
    // Streams used by the component
    associatedtype Inputs
    
    // Streams produced by the component
    associatedtype Outputs
    
    // Root view of the component, used to add as subview of parent component
    var view: UIView { get }
    
    init(disposedBy: DisposeBag)
    
    // Subscribe to input streams, export any streams produced by component
    func start(_ inputs: Inputs) -> Outputs
}

extension ViewComponent {
    // Stop any services started by the component
    func stop() {}
}
