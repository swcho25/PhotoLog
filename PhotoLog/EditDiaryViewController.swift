//
//  EditDiaryViewController.swift
//  PhotoLog
//
//  Created by seokwon on 6/15/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class EditDiaryViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var diaryImageView: UIImageView!
    @IBOutlet weak var contentTextView: UITextView!
    
    var diaryId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchDiary()
        
        titleTextView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            return false  // ✅ 엔터 입력 막기
        }
        return true
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        if contentTextView.isFirstResponder && self.view.frame.origin.y == 0 {
            self.view.frame.origin.y = -200
        }
    }


    @objc func keyboardWillHide(_ notification: Notification) {
        self.view.frame.origin.y = 0
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func fetchDiary() {
        guard let uid = Auth.auth().currentUser?.uid,
            let diaryId = diaryId else { return }

        let docRef = Firestore.firestore()
            .collection("users").document(uid)
            .collection("diaries").document(diaryId)

        docRef.getDocument { snapshot, error in
            if let error = error {
                print("❌ 일기 불러오기 실패: \(error)")
                return
            }

            if let data = snapshot?.data() {
                self.titleTextView.text = data["title"] as? String
                self.contentTextView.text = data["content"] as? String
                if let imageUrlString = data["imageURL"] as? String,
                    let url = URL(string: imageUrlString) {
                    self.diaryImageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "photo"))
                }
            }
        }
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "수정 확인", message: "수정하시겠습니까?", preferredStyle: .alert)
            
        let confirm = UIAlertAction(title: "수정", style: .default) { _ in
            self.updateDiary()
        }
            
        let cancel = UIAlertAction(title: "취소", style: .cancel, handler: nil)
            
        alert.addAction(confirm)
        alert.addAction(cancel)
        
        present(alert, animated: true, completion: nil)
    }
    
    func updateDiary() {
        guard let uid = Auth.auth().currentUser?.uid,
              let diaryId = diaryId,
              let newTitle = titleTextView.text,
              let newContent = contentTextView.text else { return }

        let docRef = Firestore.firestore()
            .collection("users").document(uid)
            .collection("diaries").document(diaryId)

        docRef.updateData([
            "title": newTitle,
            "content": newContent
        ]) { error in
            if let error = error {
                print("❌ 수정 실패: \(error)")
            } else {
                print("✅ 수정 완료")
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}
