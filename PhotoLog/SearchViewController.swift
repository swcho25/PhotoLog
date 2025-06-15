//
//  SearchViewController.swift
//  PhotoLog
//
//  Created by seokwon on 6/6/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import SDWebImage

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var filteredDiaries: [Diary] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // 🔍 검색버튼 눌렀을 때 호출
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let keyword = searchBar.text?.lowercased(), !keyword.isEmpty else { return }
        fetchMatchingDiaries(with: keyword)
        searchBar.resignFirstResponder() // 키보드 내리기
    }

    func fetchMatchingDiaries(with keyword: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(uid).collection("diaries").getDocuments { snapshot, error in
            if let error = error {
                print("❌ 검색 실패:", error)
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            self.filteredDiaries = documents.compactMap { doc in
                let data = doc.data()
                let title = (data["title"] as? String ?? "").lowercased()
                let content = (data["content"] as? String ?? "").lowercased()
                let date = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

                if title.contains(keyword) || content.contains(keyword) {
                    return Diary(id: doc.documentID,
                                 title: data["title"] as? String ?? "",
                                 date: date)
                } else {
                    return nil
                }
            }
            
            self.tableView.reloadData()
        }
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredDiaries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let diary = filteredDiaries[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "DiaryCell", for: indexPath)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"  // 원하는 포맷으로
        
        cell.textLabel?.text = "제목: " + diary.title
        cell.detailTextLabel?.text = formatter.string(from: diary.date)
        
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)     // 제목
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular) // 날짜
        
        return cell
    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedDiary = filteredDiaries[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "LogDetailVC") as? LogDetailViewController {
            detailVC.diaryId = selectedDiary.id
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
    }

}
