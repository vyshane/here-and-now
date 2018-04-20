//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import Foundation
import GoogleMaps
import RxCocoa
import RxSwift

enum UIScheme {
    case light
    case dark
    
    func style() -> UIStyle {
        switch self {
        case .light:
            return UIStyle(
                textColor: UIColor(white: 0.1, alpha: 1.0),
                hudBackgroundColor: UIColor.white.withAlphaComponent(0.2),
                defaultBackgroundColor: .white,
                temperatureColor: TemperatureColor(
                    cold: UIColor(red:0.23, green:0.69, blue:0.69, alpha:1.0),
                    cool: UIColor(red:0.21, green:0.67, blue:0.82, alpha:1.0),
                    warm: UIColor(red:0.29, green:0.57, blue:0.94, alpha:1.0),
                    warmer: UIColor(red:0.35, green:0.45, blue:0.87, alpha:1.0),
                    warmerToHot: UIColor(red:0.44, green:0.30, blue:0.94, alpha:1.0),
                    hot: UIColor(red:0.93, green:0.35, blue:0.55, alpha:1.0),
                    veryHot: UIColor(red:0.77, green:0.17, blue:0.00, alpha:1.0)
                ),
                mapStyle: lightMapStyle
            )
        case .dark:
            return UIStyle(
                textColor: UIColor(white: 0.8, alpha: 1.0),
                hudBackgroundColor: UIColor.black.withAlphaComponent(0.2),
                defaultBackgroundColor: .black,
                temperatureColor: TemperatureColor(
                    cold: UIColor(red:0.64, green:0.91, blue:1.00, alpha:1.0),
                    cool: UIColor(red:0.00, green:0.70, blue:0.88, alpha:1.0),
                    warm: UIColor(red:0.28, green:0.62, blue:1.00, alpha:1.0),
                    warmer: UIColor(red:0.04, green:0.48, blue:1.00, alpha:1.0),
                    warmerToHot: UIColor(red:0.60, green:0.43, blue:1.00, alpha:1.0),
                    hot: UIColor(red:0.95, green:0.53, blue:0.68, alpha:1.0),
                    veryHot: UIColor(red:1.00, green:0.35, blue:0.09, alpha:1.0)
                ),
                mapStyle: darkMapStyle
            )
        }
    }
}

struct UIStyle {
    let textColor: UIColor
    let hudBackgroundColor: UIColor
    let defaultBackgroundColor: UIColor
    let temperatureColor: TemperatureColor
    let mapStyle: GMSMapStyle
}

struct TemperatureColor {
    let cold: UIColor
    let cool: UIColor
    let warm: UIColor
    let warmer: UIColor
    let warmerToHot: UIColor
    let hot: UIColor
    let veryHot: UIColor
}

func uiSchemeDriver(fromLocation: Observable<CLLocation>, date: Observable<Date>) -> Driver<UIScheme> {
    return Observable
        .combineLatest(fromLocation, date) { (l, d) in
            if let isDayTime = isDaytime(date: d, coordinate: l.coordinate) {
                return isDayTime ? .light : .dark
            }
            return .light
        }
        .asDriver(onErrorJustReturn: .light)
}

fileprivate let lightMapStyle = try! GMSMapStyle(jsonString: """
    [
      {
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#e8e8e8"
          }
        ]
      },
      {
        "elementType": "labels.icon",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#727272"
          }
        ]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#f5f5f5"
          }
        ]
      },
      {
        "featureType": "administrative.land_parcel",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#999999"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#eeeeee"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#959595"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#d0d0d0"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#888888"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#ffffff"
          }
        ]
      },
      {
        "featureType": "road.arterial",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#888888"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#cecccc"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#888888"
          }
        ]
      },
      {
        "featureType": "road.local",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#888888"
          }
        ]
      },
      {
        "featureType": "transit.line",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#ffffff"
          }
        ]
      },
      {
        "featureType": "transit.station",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#dedede"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#b9bbc0"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#ffffff"
          }
        ]
      }
    ]
    """)

fileprivate let darkMapStyle = try! GMSMapStyle(jsonString: """
    [
      {
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#252525"
          }
        ]
      },
      {
        "elementType": "labels.icon",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#606060"
          }
        ]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#181818"
          }
        ]
      },
      {
        "featureType": "administrative",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#363636"
          }
        ]
      },
      {
        "featureType": "administrative.country",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#747474"
          }
        ]
      },
      {
        "featureType": "administrative.land_parcel",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "featureType": "administrative.locality",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#717171"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#666666"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#1c1c1c"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#636363"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#050505"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "geometry.fill",
        "stylers": [
          {
            "color": "#000000"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#505050"
          }
        ]
      },
      {
        "featureType": "road.arterial",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#000000"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#363636"
          }
        ]
      },
      {
        "featureType": "road.highway.controlled_access",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#363636"
          }
        ]
      },
      {
        "featureType": "road.local",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#505050"
          }
        ]
      },
      {
        "featureType": "transit",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#444444"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#00050e"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#404040"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#000000"
          }
        ]
      },
    ]
    """)
