//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import GoogleMaps
import RxCocoa
import RxCoreLocation
import RxSwift

class Map {
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
    
    struct Sinks {
        let authorization: Observable<CLAuthorizationEvent>
        let location: Observable<CLLocation?>
        let date: Observable<Date>
    }
    
    struct Sources {
        let didFinishTileRendering: Observable<Void>
        let willMove: ControlEvent<Bool>
        let idleAt: ControlEvent<GMSCameraPosition>
    }
    
    func start(_ sinks: Sinks) -> Sources {
        mapStyle(forCameraPosition: view.rx.idleAt, date: sinks.date.throttle(60, scheduler: MainScheduler.instance))
            .drive(onNext: { self.view.mapStyle = $0 })
            .disposed(by: disposedBy)
        
        shouldHideMap(forAuthorizationEvent: sinks.authorization)
            .drive(view.rx.isHidden)
            .disposed(by: disposedBy)
        
        cameraPosition(forLocation: sinks.location)
            .drive(view.rx.cameraToAnimate)
            .disposed(by: disposedBy)
        
        return Sources(
            didFinishTileRendering: view.rx.didFinishTileRendering,
            willMove: view.rx.willMove,
            idleAt: view.rx.idleAt
        )
    }
}

extension Map {
    func mapStyle(forCameraPosition: ControlEvent<GMSCameraPosition>, date: Observable<Date>) -> Driver<GMSMapStyle> {
        let location = forCameraPosition
            .asObservable()
            .map(toLocation)
        return uiScheme(fromLocation: location, date: date)
            .asDriver(onErrorJustReturn: .light)
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
            .asDriver(onErrorJustReturn: GMSCameraPosition())
    }
}
