//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import CoreLocation
import Foundation
import GoogleMaps
import RxOptional
import RxSwift

typealias ReverseGeocode = (CLLocation) -> Observable<[CLPlacemark]>

func placemarkForLocation(reverseGeocode: @escaping ReverseGeocode)
    -> (Observable<CLLocation>)
    -> Observable<CLPlacemark> {
    return {
        $0.flatMapLatest(CLGeocoder().rx.reverseGeocode)
            .map { $0.first }
            .filterNil()
    }
}

func toLocation(position: GMSCameraPosition) -> CLLocation {
    return CLLocation(latitude: position.target.latitude, longitude: position.target.longitude)
}

func toCameraPosition(location: CLLocation) -> GMSCameraPosition {
    return GMSCameraPosition.camera(withTarget: location.coordinate, zoom: 14, bearing: 0, viewingAngle: 45)
}
