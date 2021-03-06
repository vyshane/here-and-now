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
        let isMoving: Observable<Bool>
        let idleAt: Observable<GMSCameraPosition>
    }
    
    let view = UIView()
    private let mapView = createMapView()
    private let snapshotMapView = createMapView()
    private let snapshotImageView = UIImageView()
    private let disposedBy: DisposeBag

    required init(disposedBy: DisposeBag) {
        self.disposedBy = disposedBy
        
        snapshotMapView.isMyLocationEnabled = false
        snapshotMapView.settings.setAllGesturesEnabled(false)
        snapshotMapView.settings.consumesGesturesInView = false
        view.addSubview(snapshotMapView)
        snapshotMapView.easy.layout(Edges())

        view.addSubview(mapView)
        mapView.easy.layout(Edges())

        snapshotImageView.isUserInteractionEnabled = false
        snapshotImageView.fadeOut()
        view.addSubview(snapshotImageView)
        snapshotImageView.easy.layout(Edges())
    }
    
    func start(_ inputs: Inputs) -> Outputs {
        shouldHideMap(forAuthorizationEvent: inputs.authorization)
            .drive(view.rx.isHidden)
            .disposed(by: disposedBy)
        
        cameraPosition(forLocation: inputs.initialLocation)
            .drive(mapView.rx.cameraToAnimate)
            .disposed(by: disposedBy)

        let idleAt = mapView.rx.idleAt.share()
        
        idleAt
            .asDriver(onErrorDriveWith: SharedSequence.empty())
            .drive(snapshotMapView.rx.camera)
            .disposed(by: disposedBy)

        let mapStyleAtIdle = self.mapStyle(forCameraPosition: idleAt,
                                           date: inputs.date.throttle(60, scheduler: MainScheduler.instance)).share()
        
        mapStyleAtIdle
            .asDriver(onErrorDriveWith: SharedSequence.empty())
            .drive(onNext: {
                self.mapView.mapStyle = $0(true)
                self.snapshotMapView.mapStyle = $0(false)
            })
            .disposed(by: disposedBy)
        
        let didChange = mapView.rx.didChange.share()
        let isMoving = isMapMoving(idleAt: idleAt, willMove: self.mapView.rx.willMove.asObservable(),
                                   didChange: didChange).share()
        
        snapshotReady(snapshotMapView.rx.snapshotReady, isMapMoving: isMoving)
            .flatMapLatest({ _ in SharedSequence.of(self.snapshotMapView.snapshot()) })
            .drive(onNext: { image in
                self.snapshotImageView.image = image
                self.snapshotImageView.fadeIn(duration: 0.3)
            })
            .disposed(by: disposedBy)

        shouldHideSnapshotImageView(isMapMoving: isMoving)
            .drive(onNext: { _ in self.snapshotImageView.fadeOut() })
            .disposed(by: disposedBy)

        return Outputs(
            didFinishTileRendering: mapView.rx.didFinishTileRendering,
            isMoving: isMoving,
            idleAt: idleAt
        )
    }
    
    static func createMapView() -> GMSMapView {
        let mapView = GMSMapView()
        mapView.isBuildingsEnabled = true
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.rotateGestures = false
        mapView.settings.tiltGestures = false
        mapView.setMinZoom(3.0, maxZoom: 18.0)
        return mapView
    }
}

extension MapComponent {
    func mapStyle(forCameraPosition: Observable<GMSCameraPosition>, date: Observable<Date>) -> Observable<MapStyle> {
        let location = forCameraPosition
            .asObservable()
            .map(toLocation)
        return uiScheme(forLocation: location, date: date)
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
    
    func isMapMoving(idleAt: Observable<GMSCameraPosition>, willMove: Observable<Bool>,
                     didChange: Observable<GMSCameraPosition>) -> Observable<Bool> {
        return Observable
            .merge(idleAt.map { _ in false }, willMove.map { _ in true }, didChange.map { _ in true })
    }
    
    func snapshotReady(_ ready: Observable<Void>, isMapMoving: Observable<Bool>) -> Driver<Void> {
        let isReady: Observable<Void?> = ready
            .withLatestFrom(isMapMoving) { (_, isMoving) in
                if !isMoving {
                    return .some(())
                }
                return .none
        }
        return isReady
            .filterNil()
            .asDriver(onErrorDriveWith: SharedSequence.empty())
    }
    
    func shouldHideSnapshotImageView(isMapMoving: Observable<Bool>) -> Driver<Void> {
        return isMapMoving
            .filter { $0 }
            .map { _ in () }
            .asDriver(onErrorDriveWith: SharedSequence.empty())
    }
    
    private func cameraPosition(forLocation: Observable<CLLocation?>) -> Driver<GMSCameraPosition> {
        return forLocation
            .filterNil()
            .map { GMSCameraPosition.camera(withTarget: $0.coordinate, zoom: 14, bearing: 0, viewingAngle: 0) }
            .asDriver(onErrorDriveWith: SharedSequence.empty())
    }
}
