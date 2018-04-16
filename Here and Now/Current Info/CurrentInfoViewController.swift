//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import RxSwift

class CurrentInfoViewController: UIViewController, CurrentInfoController {
    private lazy var components: CurrentInfoComponents = initComponents(addToRootView: view, disposedBy: disposeBag)
    private var disposeBag = DisposeBag()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        start(components: components, disposedBy: disposeBag)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        stop(components: components)
        disposeBag = DisposeBag()
        super.viewDidDisappear(animated)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // Prevent flash of map background when reloading tiles after
        // screen dimension or aspect ratio change
        fadeIn(view: components.maskView, duration:0)
    }
}
