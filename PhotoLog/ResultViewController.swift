//
//  ResultViewController.swift
//  PhotoLog
//
//  Created by seokwon on 6/12/25.
//

import UIKit
import Photos
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class ResultViewController: UIViewController {

    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var diaryTextView: UITextView!
    
    var diaryText: String?
    var userImage: UIImage?
    var storedAsset: PHAsset?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        diaryTextView.text = diaryText
        userImageView.image = userImage
        
        // 키보드 옵저버 등록
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        // 탭하면 키보드 내리기
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        //let keyboardHeight = keyboardFrame.height
        self.view.frame.origin.y = -200 // 적당히 위로 밀기
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        self.view.frame.origin.y = 0
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @IBAction func saveLogButton(_ sender: UIButton) {
        let alert = UIAlertController(title: "일기 저장", message: "일기 제목을 입력해주세요.", preferredStyle: .alert)
            alert.addTextField { textField in
                textField.placeholder = "예: 서울에서의 하루"
            }

            alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "저장하기", style: .default, handler: { _ in
                guard let title = alert.textFields?.first?.text, !title.isEmpty else {
                    print("❌ 제목이 비어있음")
                    return
                }
                self.saveDiary(title: title)
            }))

            present(alert, animated: true)
    }
    
    func saveDiary(title: String) {
        
        guard let image = userImage,
              let diaryText = diaryText,
              let creationDate = storedAsset?.creationDate else {
            print("❌ 저장할 데이터가 부족함")
            return
        }
        
        // ✅ 저장 중 로딩 알림창 표시
            let savingAlert = showSavingAlert()
            self.present(savingAlert, animated: true, completion: nil)

        // ✅ 스토리지에 이미지 업로드
        let storage = Storage.storage()
        let storageRef = storage.reference().child("diaryImages/\(UUID().uuidString).jpg")

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ 이미지 데이터 변환 실패")
            return
        }

        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("❌ 이미지 업로드 실패:", error)
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    print("❌ URL 획득 실패:", error)
                    return
                }
                
                guard let uid = Auth.auth().currentUser?.uid else {
                    print("❌ 로그인된 사용자 없음")
                    return
                }

                guard let imageURL = url?.absoluteString else { return }

                // ✅ Firestore에 일기 데이터 저장
                let db = Firestore.firestore()
                let diaryData: [String: Any] = [
                    "title": title,
                    "content": diaryText,
                    "imageURL": imageURL,
                    "createdAt": Timestamp(date: creationDate)
                ]

                // ✅ 유저별 저장
                db.collection("users").document(uid).collection("diaries").addDocument(data: diaryData) { error in
                    DispatchQueue.main.async {
                        savingAlert.dismiss(animated: true) {
                            if let error = error {
                                print("❌ Firestore 저장 실패:", error)
                                return
                            }

                            print("✅ 일기 저장 완료")

                            // ✅ 저장 완료 알림창 띄우기
                            let alert = UIAlertController(title: "저장 완료", message: "일기가 성공적으로 저장되었습니다.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                                print("✅ 확인 버튼 눌림 - 홈 이동 시도")

                                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let window = scene.windows.first {
                                    
                                    let storyboard = UIStoryboard(name: "Main", bundle: nil)

                                    // TabBarController 인스턴스 생성
                                    if let newTabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarVC") as? UITabBarController {
                                        
                                        newTabBarController.selectedIndex = 0  // Home 탭 선택
                                        
                                        // HomeVC 네비게이션 세팅 (필요시)
                                        if let nav = newTabBarController.viewControllers?[0] as? UINavigationController,
                                           let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeVC") as? HomeViewController {
                                            nav.setViewControllers([homeVC], animated: false)
                                        }

                                        // 창에 루트로 세팅
                                        window.rootViewController = newTabBarController
                                        window.makeKeyAndVisible()
                                    }
                                }
                            })

                            // ✅ 저장 완료 알림 띄우기
                            self.present(alert, animated: true)
                        }
                    }
                }
            }
        }
    }
    
    func showSavingAlert() -> UIAlertController {
        let alert = UIAlertController(title: nil, message: "일기 저장 중...\n\n", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        
        alert.view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            loadingIndicator.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: -20)
        ])
        
        return alert
    }
}
