//
//  PictureViewController.swift
//  PhotoLog
//
//  Created by seokwon on 6/6/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import SDWebImage

struct DiaryImage {
    let id: String
    let imageURL: String
}

class PictureViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var diaryImages: [DiaryImage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        fetchImageURLs()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchImageURLs()
    }
    
    func fetchImageURLs() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).collection("diaries")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ 이미지 목록 가져오기 실패:", error)
                    return
                }
                
                self.diaryImages = snapshot?.documents.compactMap { doc in
                    guard let url = doc.data()["imageURL"] as? String else { return nil }
                    return DiaryImage(id: doc.documentID, imageURL: url)
                } ?? []
                
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    
                    if self.diaryImages.isEmpty {
                        let emptyLabel = UILabel()
                        emptyLabel.text = "일기를 작성해주세요!"
                        emptyLabel.textAlignment = .center
                        emptyLabel.textColor = UIColor(hex: "#5A2F14") // ✅ 헥사 지원
                        emptyLabel.font = UIFont.systemFont(ofSize: 17)
                        emptyLabel.numberOfLines = 0
                        self.collectionView.backgroundView = emptyLabel
                    } else {
                        self.collectionView.backgroundView = nil
                    }
                }
            }
    }
    
    // ✅ UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return diaryImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        let diaryImage = diaryImages[indexPath.item]
        if let url = URL(string: diaryImage.imageURL) {
            cell.imageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "photo"))
        }
        return cell
    }
        
    // ✅ UICollectionViewDelegate - 이미지 클릭 시 상세 페이지 이동
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let diaryImage = diaryImages[indexPath.item]
            
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "LogDetailVC") as? LogDetailViewController {
            detailVC.diaryId = diaryImage.id  // ✅ 일기 ID 전달
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
    }

    // ✅ UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 4
        let totalSpacing = spacing * 3 // (4칸 → 3개의 간격)
        let width = (collectionView.bounds.width - totalSpacing) / 4
        return CGSize(width: width, height: width)
    }
        
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 4
    }
        
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 4
    }
}
