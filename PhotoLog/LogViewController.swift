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
    
    var storedAsset: PHAsset?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(capturePicture))
        userImageView.addGestureRecognizer(imageTapGesture)
        
    }
    
    @IBAction func createLogButton(_ sender: UIButton) {
        guard let selectedImage = userImageView.image else {
            print("❌ 이미지가 선택되지 않았습니다.")
            return
        }
        
        guard let asset = self.storedAsset else {
            print("❌ PHAsset이 설정되어 있지 않습니다.")
            return
        }
        
        let creationDateString = asset.creationDate?.description ?? "날짜 없음"
        
        if let loc = asset.location {
            // 역지오코딩 수행
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(loc) { placemarks, error in
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
                
                // GPT API 호출
                self.callGPTAPI(imageDescription: metadataString) { diaryText in
                    DispatchQueue.main.async {
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        if let resultVC = storyboard.instantiateViewController(withIdentifier: "ResultVC") as? ResultViewController {
                            resultVC.diaryText = diaryText
                            resultVC.userImage = selectedImage
                            self.navigationController?.pushViewController(resultVC, animated: true)
                        }
                    }
                }
            }
        } else {
            // 위치 정보가 없는 경우
            let metadataString = "촬영 날짜: \(creationDateString), 위치 정보 없음"
            print("최종 메타데이터:", metadataString)
            
            callGPTAPI(imageDescription: metadataString) { diaryText in
                DispatchQueue.main.async {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let resultVC = storyboard.instantiateViewController(withIdentifier: "ResultVC") as? ResultViewController {
                        resultVC.diaryText = diaryText
                        resultVC.userImage = selectedImage
                        self.navigationController?.pushViewController(resultVC, animated: true)
                    }
                }
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
    
    func callGPTAPI(imageDescription: String, completion: @escaping (String) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion("테스트 일기 문구입니다.")
        }
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
        }
        
        // PHAsset을 얻어 원본 메타데이터(촬영일, 위치 등) 추출
        if let asset = info[.phAsset] as? PHAsset {
            storedAsset = asset
            // 촬영 날짜
            let creationDate = asset.creationDate ?? Date()
            print("촬영 날짜:", creationDate)
            
            // 위치 정보
            if let location = asset.location {
                print("GPS 좌표:", location.coordinate.latitude, location.coordinate.longitude)
            } else {
                print("GPS 정보 없음")
            }
            
            // 필요하면 여기에 메타데이터를 조합해 GPT API에 넘길 문자열 생성
            // 예) let metadataString = "촬영 날짜: \(creationDate), 위치: \(location.coordinate.latitude), \(location.coordinate.longitude)"
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
