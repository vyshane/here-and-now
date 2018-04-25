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
                textColor: UIColor(white: 0.05, alpha: 1.0),
                hudBackgroundColor: UIColor.white.withAlphaComponent(0.3),
                defaultBackgroundColor: .white,
                temperatureColor: TemperatureColor(
                    cold: UIColor(red:0.22, green:0.55, blue:0.55, alpha:1.0),
                    cool: UIColor(red:0.27, green:0.54, blue:0.69, alpha:1.0),
                    warm: UIColor(red:0.29, green:0.55, blue:0.84, alpha:1.0),
                    warmer: UIColor(red:0.31, green:0.43, blue:0.80, alpha:1.0),
                    warmerToHot: UIColor(red:0.44, green:0.27, blue:0.76, alpha:1.0),
                    hot: UIColor(red:0.77, green:0.25, blue:0.44, alpha:1.0),
                    veryHot: UIColor(red:0.77, green:0.30, blue:0.23, alpha:1.0)
                ),
                mapStyle: lightMapStyle
            )
        case .dark:
            return UIStyle(
                textColor: UIColor(white: 0.8, alpha: 1.0),
                hudBackgroundColor: UIColor.black.withAlphaComponent(0.3),
                defaultBackgroundColor: .black,
                temperatureColor: TemperatureColor(
                    cold: UIColor(red:0.64, green:0.91, blue:1.00, alpha:1.0),
                    cool: UIColor(red:0.00, green:0.70, blue:0.88, alpha:1.0),
                    warm: UIColor(red:0.28, green:0.62, blue:1.00, alpha:1.0),
                    warmer: UIColor(red:0.31, green:0.43, blue:0.80, alpha:1.0),
                    warmerToHot: UIColor(red:0.60, green:0.43, blue:1.00, alpha:1.0),
                    hot: UIColor(red:0.95, green:0.53, blue:0.68, alpha:1.0),
                    veryHot: UIColor(red:0.77, green:0.17, blue:0.00, alpha:1.0)
                ),
                mapStyle: darkMapStyle
            )
        }
    }
}

typealias MapStyle = (Bool) -> GMSMapStyle

struct UIStyle {
    let textColor: UIColor
    let hudBackgroundColor: UIColor
    let defaultBackgroundColor: UIColor
    let temperatureColor: TemperatureColor
    let mapStyle: (Bool) -> GMSMapStyle
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

func uiScheme(forLocation: Observable<CLLocation>, date: Observable<Date>) -> Observable<UIScheme> {
    return Observable
        .combineLatest(forLocation, date) { (l, d) in
            if let isDayTime = isDaytime(date: d, coordinate: l.coordinate) {
                return isDayTime ? .light : .dark
            }
            return .light
        }
}

func uiSchemeDriver(forLocation: Observable<CLLocation>, date: Observable<Date>) -> Driver<UIScheme> {
    return uiScheme(forLocation: forLocation, date: date)
        .asDriver(onErrorJustReturn: .light)
}

fileprivate let lightMapStyle: (Bool) -> GMSMapStyle = { isForeground in
    return try! GMSMapStyle(jsonString: """
    [
      {
        "elementType": "labels.text",
        "stylers": [
          {
            "visibility": "\(isForeground ? "on" : "off")"
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
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#ececec"
          }
        ]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#777777"
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
        "featureType": "administrative.locality",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#444444"
          }
        ]
      },
      {
        "featureType": "administrative.land_parcel",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#777777"
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
            "color": "#777777"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#dddddd"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#777777"
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
            "color": "#777777"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#ffffff"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#777777"
          }
        ]
      },
      {
        "featureType": "road.local",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#777777"
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
      },
    ]
    """)
}

fileprivate let darkMapStyle: (Bool) -> GMSMapStyle = { isForeground in
    return try! GMSMapStyle(jsonString: """
    [
      {
        "elementType": "labels.text",
        "stylers": [
          {
            "visibility": "\(isForeground ? "on" : "off")"
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
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#252525"
          }
        ]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#777777"
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
            "color": "#cccccc"
          }
        ]
      },
      {
        "featureType": "administrative.land_parcel",
        "stylers": [
          {
            "color": "777777"
          }
        ]
      },
      {
        "featureType": "administrative.locality",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#bbbbbb"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#777777"
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
            "color": "#777777"
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
            "color": "#666666"
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
            "color": "#666666"
          }
        ]
      },
      {
        "featureType": "transit",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#666666"
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
            "color": "#555555"
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
}
