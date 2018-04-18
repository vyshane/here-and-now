//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import GoogleMaps
import RxCocoa
import RxGoogleMaps
import RxCoreLocation
import RxSwift

class MapComponent {
    
    struct Inputs {
        let authorization: Observable<CLAuthorizationEvent>
        let initialLocation: Observable<CLLocation?>
        let date: Observable<Date>
    }
    
    struct Outputs {
        let didFinishTileRendering: Observable<Void>
        let willMove: ControlEvent<Bool>
        let idleAt: ControlEvent<GMSCameraPosition>
    }
    
    let view: GMSMapView
    private let disposedBy: DisposeBag

    init(disposedBy: DisposeBag) {
        self.disposedBy = disposedBy
        view = GMSMapView()
        view.isBuildingsEnabled = true
        view.isMyLocationEnabled = true
        view.settings.rotateGestures = false
        view.settings.tiltGestures = false
        view.setMinZoom(2.0, maxZoom: 18.0)
    }
    
    func start(_ inputs: Inputs) -> Outputs {
        mapStyle(forCameraPosition: view.rx.idleAt, date: inputs.date.throttle(60, scheduler: MainScheduler.instance))
            .drive(onNext: { self.view.mapStyle = $0 })
            .disposed(by: disposedBy)
        
        shouldHideMap(forAuthorizationEvent: inputs.authorization)
            .drive(view.rx.isHidden)
            .disposed(by: disposedBy)
        
        cameraPosition(forLocation: inputs.initialLocation)
            .drive(view.rx.cameraToAnimate)
            .disposed(by: disposedBy)
        
        return Outputs(
            didFinishTileRendering: view.rx.didFinishTileRendering,
            willMove: view.rx.willMove,
            idleAt: view.rx.idleAt
        )
    }
}

extension MapComponent {
    func mapStyle(forCameraPosition: ControlEvent<GMSCameraPosition>, date: Observable<Date>) -> Driver<GMSMapStyle> {
        let location = forCameraPosition
            .asObservable()
            .map(toLocation)
        return uiSchemeDriver(fromLocation: location, date: date)
            .map { $0.style().mapStyle }
    }
    
    func shouldHideMap(forAuthorizationEvent: Observable<CLAuthorizationEvent>) -> Driver<Bool> {
        return forAuthorizationEvent.map {
            switch ($0.status) {
            case .denied: return true
            case _: return false
            }
        }
        .asDriver(onErrorJustReturn: true)
    }
    
    private func cameraPosition(forLocation: Observable<CLLocation?>) -> Driver<GMSCameraPosition> {
        return forLocation
            .filterNil()
            .map { GMSCameraPosition.camera(withTarget: $0.coordinate, zoom: 14, bearing: 0, viewingAngle: 45) }
            .asDriver(onErrorDriveWith: SharedSequence.empty())
    }
}
