# Here & Now

Here & Now is an iOS weather app written in Swift. I made it to explore how I might structure an app using [RxSwift](https://github.com/ReactiveX/RxSwift).

![New York](Doc/new-york.png)
![Perth](Doc/perth.png)
![London](Doc/london.png)
![Quatre Bornes](Doc/quatre-bornes.png)

## Main Themes

* View controllers are [deliberately minimal](https://github.com/vyshane/here-and-now/blob/master/Here%20and%20Now/Current%20Info/CurrentInfoViewController.swift).
* UI logic is implemented [in protocol extensions](https://github.com/vyshane/here-and-now/blob/master/Here%20and%20Now/Current%20Info/CurrentInfoController.swift) for better testability.
* UI state changes are defined by pure functions that operate on `Observables`.