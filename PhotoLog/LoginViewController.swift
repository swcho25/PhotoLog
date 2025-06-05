//
//  LoginViewController.swift
//  PhotoLog
//
//  Created by seokwon on 6/5/25.
//

import UIKit
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

class LoginViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func googleLoginButtonTapped(_ sender: UIButton) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("❌ ClientID 누락")
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: self) { result, error in
            if let error = error {
                print("❌ 구글 로그인 실패: \(error.localizedDescription)")
                return
            }

            guard let user = result?.user,
                    let idToken = user.idToken?.tokenString else {
                print("❌ 사용자 정보 또는 토큰 누락")
                return
            }

            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("❌ Firebase 로그인 실패: \(error.localizedDescription)")
                    return
                }

                print("✅ 로그인 성공! 유저: \(authResult?.user.email ?? "")")
                self.goToHomeScreen()
            }
        }
    }

    func goToHomeScreen() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let sceneDelegate = windowScene.delegate as? SceneDelegate,
                let homeVC = storyboard?.instantiateViewController(withIdentifier: "HomeVC") else {
            print("❌ HomeVC 로드 실패")
            return
        }

        let navController = UINavigationController(rootViewController: homeVC)
        sceneDelegate.window?.rootViewController = navController
        sceneDelegate.window?.makeKeyAndVisible()
    }

}
