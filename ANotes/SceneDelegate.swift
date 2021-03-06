//
//  SceneDelegate.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 24.10.2020.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, ApplicationLockBiometricAuthenticationDelegate {
    var isUnlocked: Bool?
    var userStore: UserStore!
    // Workaround for prevent initialization scene and create ViewControllers when application
    // has been closed after run in shortly time.
    // Started use FaceID we faced with blinking FaceID view after swipe application from runs.
    static var viewCreationPermit: Bool! = true
    
    func setSuccessedUnlock() {
        self.userStore.user?.unlocked = true
    }
    
    func setPasscode(passcode: String) {
        self.userStore.user!.passcode = passcode
    }
    
    func completionIfSuccess(vc: UIViewController?) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let mainNC = mainStoryboard.instantiateViewController(identifier: "MainNavigationController") as? MainNavigationController,
              let notesVC = mainNC.children.first as? NotesTableViewController else {
            print("Error when instantiate mainNC and notesVC")
            return
        }
        
        notesVC.userStore = self.userStore
        UIView.transition(with: self.window!, duration: 0.5, options: .transitionFlipFromRight, animations: {
            self.window!.rootViewController = mainNC
        })
    }
    

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        guard SceneDelegate.viewCreationPermit == true else {return}
        self.userStore = UserStore()
        if let user = User.getLastSessionUser() {
            userStore.user = user
            if User.appLocked {
                let pinPassStoryBoard = UIStoryboard(name: "PinPass", bundle: nil)
                guard let pinPassVC = pinPassStoryBoard.instantiateViewController(identifier: "PinPassViewController") as? PinPassViewController else {
                    print("Instantiate 'PinPassViewController' from 'PinPass' storyboard failed.")
                    return
                }
                
                pinPassVC.originPasscode = user.passcode
                pinPassVC.setUp = false
                pinPassVC.userStore = self.userStore
                pinPassVC.delegate = self
                self.window!.rootViewController = pinPassVC
            }
            else {
                let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                guard let mainNC = mainStoryboard.instantiateViewController(identifier: "MainNavigationController") as?     MainNavigationController,
                    let notesVC = mainNC.children.first as? NotesTableViewController else {
                    print("Error when instantiate mainNC and notesVC")
                    return
                }
                notesVC.userStore = userStore
                self.window!.rootViewController = mainNC
            }
        }
        else {
            let loginVC = window!.rootViewController as! LoginViewController
            loginVC.userStore = userStore
        }
    }
    
    

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        SceneDelegate.viewCreationPermit = true
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        SceneDelegate.viewCreationPermit = false
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

