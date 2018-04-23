//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import EasyPeasy
import GoogleMaps
import RxCocoa
import RxGoogleMaps
import RxCoreLocation
import RxSwift

class MapComponent: ViewComponent {
    
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
    
    let view = UIView()
    let mapView = GMSMapView()
    private let disposedBy: DisposeBag

    required init(disposedBy: DisposeBag) {
        self.disposedBy = disposedBy
        mapView.isBuildingsEnabled = true
        mapView.isMyLocationEnabled = true
        mapView.settings.rotateGestures = false
        mapView.settings.tiltGestures = false
        mapView.setMinZoom(3.0, maxZoom: 18.0)
        view.addSubview(mapView)
        mapView.easy.layout(Edges())
    }
    
    func start(_ inputs: Inputs) -> Outputs {
        mapStyle(forCameraPosition: mapView.rx.idleAt, date: inputs.date.throttle(60, scheduler: MainScheduler.instance))
            .drive(onNext: { self.mapView.mapStyle = $0 })
            .disposed(by: disposedBy)
        
        shouldHideMap(forAuthorizationEvent: inputs.authorization)
            .drive(view.rx.isHidden)
            .disposed(by: disposedBy)
        
        cameraPosition(forLocation: inputs.initialLocation)
            .drive(mapView.rx.cameraToAnimate)
            .disposed(by: disposedBy)
        
        return Outputs(
            didFinishTileRendering: mapView.rx.didFinishTileRendering,
            willMove: mapView.rx.willMove,
            idleAt: mapView.rx.idleAt
        )
    }
}

extension MapComponent {
    func mapStyle(forCameraPosition: ControlEvent<GMSCameraPosition>, date: Observable<Date>) -> Driver<GMSMapStyle> {
        let location = forCameraPosition
            .asObservable()
            .map(toLocation)
        return uiSchemeDriver(fromLocation: location, date: date)
            .map { $0.style().mapStyle(true) }
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
            .map { GMSCameraPosition.camera(withTarget: $0.coordinate, zoom: 14, bearing: 0, viewingAngle: 0) }
            .asDriver(onErrorDriveWith: SharedSequence.empty())
    }
}
