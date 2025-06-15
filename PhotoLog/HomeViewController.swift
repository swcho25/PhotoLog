//
//  HomeViewController.swift
//  PhotoLog
//
//  Created by seokwon on 6/5/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

struct Diary {
    let id: String
    let title: String
    let date: Date
}

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var yearPicker: UIPickerView!
    @IBOutlet weak var monthPicker: UIPickerView!
    
    let years = Array(2020...Calendar.current.component(.year, from: Date()))
    let months = Array(1...12)
    var diaryList: [Diary] = []
    var selectedYear: Int = Calendar.current.component(.year, from: Date())
    var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    var availableYearMonth: [Int: [Int]] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        tableView.dataSource = self
        tableView.delegate = self

        yearPicker.delegate = self
        yearPicker.dataSource = self
        monthPicker.delegate = self
        monthPicker.dataSource = self

        loadAvailableYearMonth()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadAvailableYearMonth()
    }
    
    func fetchDiaries(forYear year: Int, month: Int) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let calendar = Calendar.current
        let startComponents = DateComponents(year: year, month: month, day: 1)
        let endComponents = DateComponents(year: year, month: month + 1, day: 1)

        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(from: endComponents) else { return }

        let db = Firestore.firestore()
        db.collection("users").document(uid).collection("diaries")
            .whereField("createdAt", isGreaterThanOrEqualTo: startDate)
            .whereField("createdAt", isLessThan: endDate)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
            if let error = error {
                print("❌ 데이터 가져오기 실패:", error)
                return
            }

            self.diaryList = snapshot?.documents.compactMap { doc in
                let data = doc.data()
                return Diary(
                    id: doc.documentID,
                    title: data["title"] as? String ?? "",
                    date: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                )
            } ?? []
            self.tableView.reloadData()
        }
    }
    
    func loadAvailableYearMonth() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(uid).collection("diaries")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
            if let error = error {
                print("❌ 전체 일기 목록 조회 실패:", error)
                return
            }

            var yearMonthDict: [Int: Set<Int>] = [:]

            snapshot?.documents.forEach { doc in
                if let timestamp = doc.data()["createdAt"] as? Timestamp {
                    let date = timestamp.dateValue()
                    let year = Calendar.current.component(.year, from: date)
                    let month = Calendar.current.component(.month, from: date)
                    yearMonthDict[year, default: []].insert(month)
                }
            }

            // 정렬
            self.availableYearMonth = yearMonthDict.mapValues { months in
                months.sorted(by: >)
            }.sorted(by: { $0.key > $1.key })
             .reduce(into: [:]) { $0[$1.key] = $1.value }

            // Picker 새로고침
            self.yearPicker.reloadAllComponents()
            self.monthPicker.reloadAllComponents()

            // ✅ 현재 선택된 연/월이 여전히 유효한지 확인
            if let validMonths = self.availableYearMonth[self.selectedYear],
               validMonths.contains(self.selectedMonth) {
                // 유효 → 그대로 유지
                if let yearIndex = Array(self.availableYearMonth.keys.sorted(by: >)).firstIndex(of: self.selectedYear),
                   let monthIndex = validMonths.firstIndex(of: self.selectedMonth) {
                    self.yearPicker.selectRow(yearIndex, inComponent: 0, animated: false)
                    self.monthPicker.selectRow(monthIndex, inComponent: 0, animated: false)
                    self.fetchDiaries(forYear: self.selectedYear, month: self.selectedMonth)
                }
            } else if let latestYear = self.availableYearMonth.keys.sorted(by: >).first,
                      let latestMonth = self.availableYearMonth[latestYear]?.first {
                // 유효하지 않음 → 최신으로 fallback
                self.selectedYear = latestYear
                self.selectedMonth = latestMonth

                if let yearIndex = Array(self.availableYearMonth.keys.sorted(by: >)).firstIndex(of: latestYear) {
                    self.yearPicker.selectRow(yearIndex, inComponent: 0, animated: false)
                }
                if let monthIndex = self.availableYearMonth[latestYear]?.firstIndex(of: latestMonth) {
                    self.monthPicker.selectRow(monthIndex, inComponent: 0, animated: false)
                }

                self.fetchDiaries(forYear: latestYear, month: latestMonth)
            } else {
                // 일기 없음
                let emptyLabel = UILabel()
                emptyLabel.text = "일기를 작성해주세요!"
                emptyLabel.textAlignment = .center
                emptyLabel.textColor = UIColor(hex: "#5A2F14")
                emptyLabel.font = UIFont.systemFont(ofSize: 17)
                emptyLabel.numberOfLines = 0
                self.tableView.backgroundView = emptyLabel
                self.tableView.separatorStyle = .none
                self.diaryList = []
                self.tableView.reloadData()
            }
        }
    }

    
    // ✅ TableView - 셀 개수
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return diaryList.count
    }
        
    // ✅ TableView - 셀 내용
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let diary = diaryList[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "LogCell", for: indexPath)
            
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
            
        cell.textLabel?.text = "\(formatter.string(from: diary.date))\n제목: \(diary.title)"
        cell.textLabel?.numberOfLines = 0
        return cell
    }
        
    // ✅ TableView - 셀 클릭 → 상세화면 이동
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedDiary = diaryList[indexPath.row]
            
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "LogDetailVC") as? LogDetailViewController {
            detailVC.diaryId = selectedDiary.id
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == yearPicker {
            return availableYearMonth.keys.count
        } else {
            let years = Array(availableYearMonth.keys).sorted()
            let selectedIndex = yearPicker.selectedRow(inComponent: 0)
            
            // ✅ 인덱스가 유효한지 확인
            guard selectedIndex < years.count else {
                return 0
            }
            
            let selectedYear = years[selectedIndex]
            return availableYearMonth[selectedYear]?.count ?? 0
        }
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()

        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 17) // 원하는 크기
        label.textColor = UIColor.darkGray

        if pickerView == yearPicker {
            let years = Array(availableYearMonth.keys).sorted(by: >)
            if row < years.count {
                label.text = "\(years[row])년"
            }
        } else {
            let years = Array(availableYearMonth.keys).sorted(by: >)
            let selectedYearIndex = yearPicker.selectedRow(inComponent: 0)
            if selectedYearIndex < years.count {
                let selectedYear = years[selectedYearIndex]
                if let months = availableYearMonth[selectedYear], row < months.count {
                    label.text = "\(months[row])월"
                }
            }
        }

        return label
    }


    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let years = Array(availableYearMonth.keys).sorted(by: >)
        let selectedYearIndex = yearPicker.selectedRow(inComponent: 0)
        guard selectedYearIndex < years.count else { return }

        let selectedYear = years[selectedYearIndex]
        guard let months = availableYearMonth[selectedYear] else { return }

        var selectedMonth = months.first ?? 1
        let selectedMonthIndex = monthPicker.selectedRow(inComponent: 0)
        if selectedMonthIndex < months.count {
            selectedMonth = months[selectedMonthIndex]
        }

        self.selectedYear = selectedYear
        self.selectedMonth = selectedMonth

        if pickerView == yearPicker {
            monthPicker.reloadAllComponents()
            monthPicker.selectRow(0, inComponent: 0, animated: true)
        }

        fetchDiaries(forYear: selectedYear, month: selectedMonth)
    }

}
