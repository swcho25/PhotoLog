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
import DGCharts

class SettingViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var diaryCountLabel: UILabel!
    @IBOutlet weak var chartView: BarChartView!
    
    let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "일기를 작성해주세요!"
        label.textAlignment = .center
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.layer.cornerRadius = imageView.frame.height/2
        imageView.layer.borderWidth = 1
        imageView.clipsToBounds = true
        imageView.layer.borderColor = UIColor.clear.cgColor
        
        view.addSubview(emptyLabel)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: chartView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: chartView.centerYAnchor)
        ])
        
        loadUserInfo()
        loadDiaryCount()
        loadMonthlyDiaryStats()
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
    
    func loadMonthlyDiaryStats() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(uid).collection("diaries").getDocuments { snapshot, error in
            if let error = error {
                print("❌ 일기 불러오기 실패: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                // 🔴 일기 없음 → 그래프 숨기고 안내 문구
                DispatchQueue.main.async {
                self.chartView.isHidden = true
                self.emptyLabel.isHidden = false
                }
                return
            }

            var monthCounter: [String: Int] = [:]
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"

            snapshot?.documents.forEach { doc in
                if let timestamp = doc.data()["createdAt"] as? Timestamp {
                    let month = formatter.string(from: timestamp.dateValue())
                    monthCounter[month, default: 0] += 1
                }
            }

            // 많이 작성한 순서로 상위 5개 정렬
            let top5 = monthCounter.sorted { $0.value > $1.value }.prefix(5)

            let labels = top5.map { $0.key }
            let values = top5.map { Double($0.value) }

            DispatchQueue.main.async {
                self.updateBarChart(labels: labels, values: values)
            }
        }
    }
    
    func updateBarChart(labels: [String], values: [Double]) {
        var entries: [BarChartDataEntry] = []

        for (i, value) in values.enumerated() {
            entries.append(BarChartDataEntry(x: Double(i), y: value))
        }

        let dataSet = BarChartDataSet(entries: entries, label: "월별 일기 수")
        dataSet.colors = [UIColor(hex: "#5A2F14")]

        let data = BarChartData(dataSet: dataSet)

        // ✅ 숫자 포맷터 설정
        let numberFormatter = NumberFormatter()
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 0
        data.setValueFormatter(DefaultValueFormatter(formatter: numberFormatter))

        chartView.data = data

        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.granularity = 1

        chartView.leftAxis.axisMinimum = 0
        chartView.leftAxis.granularity = 1
        chartView.leftAxis.labelCount = 5
        chartView.leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: numberFormatter)

        chartView.rightAxis.enabled = false
        chartView.legend.enabled = false
        chartView.animate(yAxisDuration: 1.0)
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
