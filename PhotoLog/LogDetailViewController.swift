//
//  LogDetailViewController.swift
//  PhotoLog
//
//  Created by seokwon on 6/6/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import SDWebImage

class LogDetailViewController: UIViewController {
    
    var diaryId: String?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var contentLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchDiaryDetail()
    }
    
    func fetchDiaryDetail() {
        guard let uid = Auth.auth().currentUser?.uid,
              let diaryId = diaryId else { return }

        let db = Firestore.firestore()
        db.collection("users").document(uid).collection("diaries").document(diaryId).getDocument { snapshot, error in
            if let error = error {
                print("❌ 일기 조회 실패:", error)
                return
            }

            guard let data = snapshot?.data() else { return }

            let title = data["title"] as? String ?? ""
            let content = data["content"] as? String ?? ""
            let imageURL = data["imageURL"] as? String ?? ""
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()

            DispatchQueue.main.async {
                self.titleLabel.text = "제목: " + title

                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy년 M월 d일"
                let formattedDate = createdAt != nil ? formatter.string(from: createdAt!) : "날짜 없음"
                self.dateLabel.text = "날짜: " + formattedDate

                self.contentLabel.text = content

                if let url = URL(string: imageURL) {
                    self.imageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "photo"))
                }
            }
        }
    }
}
