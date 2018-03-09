//  Copyright © 2018 Vy-Shane Xie. All rights reserved.

import EasyPeasy
import RxSwift
import UIKit

class MainViewController: UIViewController, MainController {
    private var ui: UI?
    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        ui = initUI(rootView: view)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let ui = ui {
            startUI(currentDate: currentDate)(ui, disposeBag)
        }
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disposeBag = DisposeBag()
    }
}

struct UI {
    let timeLabel: UILabel
}

protocol MainController { }

extension MainController {
    
    func initUI(rootView: UIView) -> UI {
        // Time
        let timeLabel = UILabel()
        timeLabel.easy.layout(Width(200), Height(120))
        rootView.addSubview(timeLabel)
        
        return UI(timeLabel: timeLabel)
    }

    func startUI(currentDate: @escaping CurrentDate) -> (_ ui: UI, _ disposeBag: DisposeBag) -> Void {
        return { (ui: UI, disposeBag: DisposeBag) in
            // Time
            currentDate()
                .map { formattedTime(date: $0) }
                .observeOn(MainScheduler())
                .subscribe(onNext: { t in ui.timeLabel.text = t })
                .disposed(by: disposeBag)
        }
    }
}
