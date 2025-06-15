//
//  SettingViewController.swift
//  PhotoLog
//
//  Created by seokwon on 6/6/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

class SettingViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var diaryCountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.layer.cornerRadius = imageView.frame.height/2
        imageView.layer.borderWidth = 1
        imageView.clipsToBounds = true
        imageView.layer.borderColor = UIColor.clear.cgColor
        
        loadUserInfo()
        loadDiaryCount()
    }

    func loadUserInfo() {
        if let user = Auth.auth().currentUser {
            // ✅ 프로필 이미지
            if let photoURL = user.photoURL {
                imageView.sd_setImage(with: photoURL, placeholderImage: UIImage(systemName: "person.circle"))
            }

            // ✅ 닉네임
            let nicknameValue = user.displayName ?? "익명 사용자"
            nicknameLabel.text = "사용자 닉네임: " + nicknameValue
        }
    }

    func loadDiaryCount() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(uid).collection("diaries").getDocuments { snapshot, error in
            if let error = error {
                print("❌ 일기 수 조회 실패: \(error)")
                return
            }

            let count = snapshot?.documents.count ?? 0
            self.diaryCountLabel.text = "작성한 일기: 총 \(count)개"
        }
    }
    
    @IBAction func logoutButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "로그아웃", message: "정말 로그아웃하시겠습니까?", preferredStyle: .alert)

        // ✅ 확인 액션
        let confirm = UIAlertAction(title: "로그아웃", style: .destructive) { _ in
            self.performLogout()
        }

        // ✅ 취소 액션
        let cancel = UIAlertAction(title: "취소", style: .cancel, handler: nil)

        alert.addAction(confirm)
        alert.addAction(cancel)

        present(alert, animated: true, completion: nil)
    }
    
    func performLogout() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()

            // 초기 로그인 화면으로 이동
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let delegate = windowScene.delegate as? SceneDelegate {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC")
                delegate.window?.rootViewController = loginVC
            }

        } catch {
            print("❌ 로그아웃 실패: \(error)")
        }
    }

}
