//
//  ResultViewController.swift
//  PhotoLog
//
//  Created by seokwon on 6/12/25.
//

import UIKit

class ResultViewController: UIViewController {

    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var diaryTextView: UITextView!
    
    var diaryText: String?
    var userImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        diaryTextView.text = diaryText
        userImageView.image = userImage
    }

    @IBAction func saveLogButton(_ sender: UIButton) {
    }
    
}
