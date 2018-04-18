//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import CoreLocation
import EasyPeasy
import RxSwift

class CurrentInfoViewController: UIViewController {
    private var disposeBag = DisposeBag()
    private let locationManager = CLLocationManager()
    private lazy var currentInfo = CurrentInfoComponent(disposedBy: disposeBag)
    private let viewTransition: BehaviorSubject<Void> = BehaviorSubject(value: ())

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 20
        locationManager.startUpdatingLocation()
        view.addSubview(currentInfo.view)
        currentInfo.view.easy.layout(Edges())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        currentInfo.start(
            CurrentInfoComponent.Inputs(
                authorization: locationManager.rx.didChangeAuthorization.asObservable(),
                initialLocation: locationManager.rx.location.take(1),
                date: currentDate().share(),
                viewTransition: viewTransition
            )
        )
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        locationManager.stopUpdatingLocation()
        disposeBag = DisposeBag()
        super.viewWillDisappear(animated)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        viewTransition.on(.next(()))
    }
}
