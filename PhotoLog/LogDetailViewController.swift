//
//  LogDetailViewController.swift
//  PhotoLog
//
//  Created by seokwon on 6/6/25.
//

import UIKit

class LogDetailViewController: UIViewController {

    var diaryId: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        print("받아온 일기 ID: \(diaryId ?? "없음")")

    }
}
