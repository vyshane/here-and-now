//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import EasyPeasy
import RxSwift
import UIKit

class MainViewController: UIViewController, MainController {
    private var mainUI: MainUI?
    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        mainUI = initUI(rootView: view, disposeBag: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let mainUI = mainUI {
            startUI(currentDate: currentDate)(mainUI, disposeBag)
        }
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopUI(disposeBag: &disposeBag)
    }
}

struct MainUI {
    let timeLabel: UILabel
}

protocol MainController { }

extension MainController {
    
    // Idempotent
    func initUI(rootView: UIView, disposeBag: inout DisposeBag) -> MainUI {
        // Reset
        stopUI(disposeBag: &disposeBag)
        rootView.subviews.forEach { $0.removeFromSuperview() }
        
        // Layout views
        // Time
        let timeLabel = UILabel()
        timeLabel.easy.layout(
            Width(200),
            Height(120)
        )
        rootView.addSubview(timeLabel)
        
        return MainUI(timeLabel: timeLabel)
    }

    func startUI(currentDate: @escaping CurrentDate) -> (_ mainUI: MainUI, _ disposeBag: DisposeBag) -> Void {
        return { (mainUI: MainUI, disposeBag: DisposeBag) in
            // Time
            currentDate()
                .map { formattedTime(date: $0) }
                .observeOn(MainScheduler())
                .subscribe(onNext: { t in mainUI.timeLabel.text = t })
                .disposed(by: disposeBag)
        }
    }
    
    func stopUI(disposeBag: inout DisposeBag) -> Void {
        disposeBag = DisposeBag()
    }
}
