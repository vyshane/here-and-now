//
//  CLGeocoder+Rx.swift
//  Source: https://gist.github.com/faiare/86894f06bac20ad3bc0f84f993608086
//
//  Created by Faiare on 10/24/17.
//  Copyright © 2017 Faiare. MIT License.
//

import CoreLocation
import RxSwift

extension Reactive where Base:CLGeocoder {
    
    func reverseGeocode(location: CLLocation) -> Observable<[CLPlacemark]> {
        return Observable<[CLPlacemark]>.create { observer in
            self.base.reverseGeocodeLocation(location) { placemarks, error in
                if let placemarks = placemarks {
                    observer.onNext(placemarks)
                    observer.onCompleted()
                }
                else if let error = error {
                    observer.onError(error)
                }
                else {
                    observer.onError(RxError.unknown)
                }
            }
            return Disposables.create { self.base.cancelGeocode() }
        }
    }
    
    func geocodeAddressDictionary(addressDictionary: [NSObject : AnyObject]) -> Observable<[CLPlacemark]> {
        return Observable<[CLPlacemark]>.create { observer in
            self.base.geocodeAddressDictionary(addressDictionary) { placemarks, error in
                if let placemarks = placemarks {
                    observer.onNext(placemarks)
                    observer.onCompleted()
                }
                else if let error = error {
                    observer.onError(error)
                }
                else {
                    observer.onError(RxError.unknown)
                }
            }
            return Disposables.create { self.base.cancelGeocode() }
        }
    }
    
    func geocodeAddressString(addressString: String) -> Observable<[CLPlacemark]> {
        return Observable<[CLPlacemark]>.create { observer in
            self.base.geocodeAddressString(addressString) { placemarks, error in
                if let placemarks = placemarks {
                    observer.onNext(placemarks)
                    observer.onCompleted()
                }
                else if let error = error {
                    observer.onError(error)
                }
                else {
                    observer.onError(RxError.unknown)
                }
            }
            return Disposables.create { self.base.cancelGeocode() }
        }
    }
    
    func geocodeAddressString(addressString: String, inRegion region: CLRegion?) -> Observable<[CLPlacemark]> {
        return Observable<[CLPlacemark]>.create { observer in
            self.base.geocodeAddressString(addressString) { placemarks, error in
                if let placemarks = placemarks {
                    observer.onNext(placemarks)
                    observer.onCompleted()
                }
                else if let error = error {
                    observer.onError(error)
                }
                else {
                    observer.onError(RxError.unknown)
                }
            }
            return Disposables.create { self.base.cancelGeocode() }
        }
    }
}
