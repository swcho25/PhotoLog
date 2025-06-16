//
//  LogViewController.swift
//  PhotoLog
//
//  Created by seokwon on 6/6/25.
//

import UIKit
import Photos
import CoreLocation

class LogViewController: UIViewController {

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var placeholderLabel: UILabel!
    
    var storedAsset: PHAsset?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(capturePicture))
        userImageView.addGestureRecognizer(imageTapGesture)
        
    }
    
    @IBAction func createLogButton(_ sender: UIButton) {
        guard let selectedImage = userImageView.image else {
            let alert = UIAlertController(title: "사진 필요", message: "사진을 선택해주세요!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            self.present(alert, animated: true)
            print("❌ 이미지가 선택되지 않았습니다.")
            return
        }

        guard let asset = self.storedAsset else {
            print("❌ PHAsset이 설정되어 있지 않습니다.")
            return
        }

        let creationDateString = asset.creationDate?.description ?? "날짜 없음"

        // ✅ 로딩창 표시
        let loadingAlert = showLoadingAlert()
        self.present(loadingAlert, animated: true, completion: nil)
            
        if let loc = asset.location {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(loc, preferredLocale: .current) { placemarks, error in
                var locationString = "위치 정보 없음"
                
                if let error = error {
                    print("역지오코딩 실패:", error.localizedDescription)
                } else if let placemark = placemarks?.first {
                    let country = placemark.country ?? "국가 알 수 없음"
                    let city = placemark.locality ?? "도시 알 수 없음"
                    let district = placemark.subLocality ?? "구 정보 없음"
                    locationString = "나라: \(country), 도시: \(city), 상세: \(district)"
                }

                let metadataString = "촬영 날짜: \(creationDateString), 위치: \(locationString)"
                print("최종 메타데이터:", metadataString)

                // 1. 예시 데이터
                let dummyDiaryText = """
                오사카의 맑은 겨울날, 우리는 유니버설 스튜디오를 찾았다.
                사진 속 환한 웃음은 그날의 즐거움을 고스란히 담고 있다.
                여행의 기록이 또 하나의 소중한 추억이 되었다.
                """
                    
                DispatchQueue.main.async {
                    loadingAlert.dismiss(animated: true) {
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        if let resultVC = storyboard.instantiateViewController(withIdentifier: "ResultVC") as? ResultViewController {
                            resultVC.diaryText = dummyDiaryText
                            resultVC.userImage = selectedImage
                            resultVC.storedAsset = asset
                            self.navigationController?.pushViewController(resultVC, animated: true)
                        }
                    }
                }
                    
                // 2. GPT API 호출
                /*self.callGPTAPI(image: selectedImage, metadata: metadataString) { diaryText in
                    DispatchQueue.main.async {
                        loadingAlert.dismiss(animated: true) {
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            if let resultVC = storyboard.instantiateViewController(withIdentifier: "ResultVC") as? ResultViewController {
                                resultVC.diaryText = diaryText
                                resultVC.userImage = selectedImage
                                resultVC.storedAsset = asset
                                self.navigationController?.pushViewController(resultVC, animated: true)
                            }
                        }
                    }
                }*/
            }
        }
    }
    
    @objc func capturePicture(sender: UITapGestureRecognizer) {
        checkPhotoLibraryPermission { granted in
            if granted {
                DispatchQueue.main.async {
                    let imagePickerController = UIImagePickerController()
                    imagePickerController.delegate = self
                    // 카메라 대신 갤러리에서만 선택하도록 고정
                    imagePickerController.sourceType = .photoLibrary
                    self.present(imagePickerController, animated: true, completion: nil)
                }
            } else {
                // 권한 거부 안내 코드 유지
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "권한 필요", message: "사진 라이브러리 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
                        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(appSettings)
                        }
                    })
                    alert.addAction(UIAlertAction(title: "취소", style: .cancel))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    func showLoadingAlert() -> UIAlertController {
        let alert = UIAlertController(title: nil, message: "일기 생성 중...\n\n", preferredStyle: .alert)

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
    
    func callGPTAPI(image: UIImage, metadata: String, completion: @escaping (String) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions"),
              let imageData = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() else {
            completion("입력 오류 발생")
            return
        }
        
        guard let apiKey = Bundle.main.infoDictionary?["OpenAI_API_Key"] as? String else {
            print("❌ API 키 로드 실패")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let imageDict: [String: Any] = [
            "type": "image_url",
            "image_url": [
                "url": "data:image/jpeg;base64,\(imageData)"
            ]
        ]
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": "당신은 여행 일기를 대신 써주는 작가입니다."],
            ["role": "user", "content": [
                [
                    "type": "text",
                    "text": "아래 이미지와 메타데이터를 참고해서 감성적인 여행 일기를 3문장으로 작성해줘. \n메타데이터: \(metadata)"
                ],
                imageDict
            ]]
        ]
        
        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "max_tokens": 300
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("JSON 변환 실패: \(error)")
            completion("요청 생성 실패")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 네트워크 오류 발생:", error)
                completion("요청 중 오류 발생")
                return
            }
            
            guard let data = data else {
                print("❌ 응답 데이터 없음")
                completion("응답 데이터 없음")
                return
            }
            
            // ✅ JSON 파싱 시도
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("❌ JSON 최상위 파싱 실패")
                    completion("JSON 최상위 파싱 실패")
                    return
                }

                guard
                    let choices = json["choices"] as? [[String: Any]],
                    let message = choices.first?["message"] as? [String: Any],
                    let content = message["content"] as? String
                else {
                    print("❌ JSON 구조 예상과 다름:\n\(json)")
                    completion("응답 파싱 실패")
                    return
                }
                
                print("✅ 생성된 일기 내용:\n\(content)")
                completion(content)

            } catch {
                print("❌ JSON 파싱 실패: \(error)")
                completion("응답 파싱 중 오류 발생")
            }
        }
        
        task.resume()
    }
    
    func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            // 권한 있음
            completion(true)
        case .notDetermined:
            // 처음 요청하는 경우
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        case .denied, .restricted:
            // 권한 없음
            completion(false)
        @unknown default:
            completion(false)
        }
    }
}

extension LogViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate{
    // 반드시 UINavigationControllerDelegate도 상속받아야 한다
    // 사진을 찍은 경우 호출되는 함수
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            userImageView.image = image
            placeholderLabel.isHidden = true
        }
        
        // PHAsset을 얻어 원본 메타데이터(촬영일, 위치 등) 추출
        if let asset = info[.phAsset] as? PHAsset {
            let hasDate = asset.creationDate != nil
            let hasLocation = asset.location != nil

            // 날짜와 위치 정보가 모두 없는 경우 → 경고 표시하고 무효화
            if !hasDate || !hasLocation {
                // 선택 무효화 처리
                storedAsset = nil
                userImageView.image = nil
                placeholderLabel.isHidden = false

                let alert = UIAlertController(title: "사용할 수 없는 사진", message: "이 사진에는 촬영 날짜나 위치 정보가 없어 사용할 수 없습니다.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                
                picker.dismiss(animated: true) {
                    self.present(alert, animated: true)
                }
                
            } else {
                // 조건 만족 시 저장
                storedAsset = asset

                if let date = asset.creationDate {
                    print("촬영 날짜:", date)
                } else {
                    print("촬영 날짜 없음")
                }

                if let location = asset.location {
                    print("GPS 좌표:", location.coordinate.latitude, location.coordinate.longitude)
                } else {
                    print("GPS 정보 없음")
                }
                }
        } else {
            print("PHAsset을 가져올 수 없습니다.")
        }

        picker.dismiss(animated: true, completion: nil)
    }
    
    // 사진 캡쳐를 취소하는 경우 호출 함수
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // imagePickerController을 죽인다
        picker.dismiss(animated: true, completion: nil)
    }

}
