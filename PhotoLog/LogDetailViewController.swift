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
        setupNavigationBar()
        fetchDiaryDetail()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchDiaryDetail()  // ✅ 매번 다시 불러오기
    }
    
    func setupNavigationBar() {
        let moreButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(showActionSheet))
        navigationItem.rightBarButtonItem = moreButton
    }
    
    @objc func showActionSheet() {
        let alert = UIAlertController(title: "옵션 선택", message: nil, preferredStyle: .actionSheet)

        // ✅ 수정
        let editAction = UIAlertAction(title: "수정", style: .default) { _ in
            self.navigateToEdit()
        }

        // ✅ 삭제
        let deleteAction = UIAlertAction(title: "삭제", style: .destructive) { _ in
            self.confirmDelete()
        }

        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(editAction)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }
    
    func navigateToEdit() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let editVC = storyboard.instantiateViewController(withIdentifier: "EditDiaryVC") as? EditDiaryViewController {
            editVC.diaryId = self.diaryId
            navigationController?.pushViewController(editVC, animated: true)
        }
    }
    
    func confirmDelete() {
        let alert = UIAlertController(title: "일기 삭제", message: "정말 삭제하시겠습니까?", preferredStyle: .alert)

        let delete = UIAlertAction(title: "삭제", style: .destructive) { _ in
            self.deleteDiary()
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(delete)
        alert.addAction(cancel)

        present(alert, animated: true)
    }
    
    func deleteDiary() {
        guard let uid = Auth.auth().currentUser?.uid,
              let diaryId = diaryId else { return }

        Firestore.firestore()
            .collection("users").document(uid)
            .collection("diaries").document(diaryId)
            .delete { error in
            if let error = error {
                print("❌ 삭제 실패: \(error)")
            } else {
                print("✅ 삭제 성공")
                self.navigationController?.popViewController(animated: true)
            }
        }
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
