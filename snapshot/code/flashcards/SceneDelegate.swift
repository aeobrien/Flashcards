//
//  SceneDelegate.swift
//  flashcards
//
//  Created by Danuja Jayasuriya on 2024-04-09.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }

        // Replace Favourites tab (index 1) with Groups tab after storyboard loads
        DispatchQueue.main.async { [weak self] in
            guard let tabBarController = self?.window?.rootViewController as? UITabBarController else { return }

            let groupsVC = GroupsViewController()
            let groupsNav = UINavigationController(rootViewController: groupsVC)
            groupsNav.navigationBar.prefersLargeTitles = true
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
            groupsNav.navigationBar.standardAppearance = appearance
            groupsNav.tabBarItem = UITabBarItem(title: "Groups", image: UIImage(systemName: "rectangle.stack"), selectedImage: UIImage(systemName: "rectangle.stack.fill"))

            if var viewControllers = tabBarController.viewControllers, viewControllers.count > 1 {
                viewControllers[1] = groupsNav
                tabBarController.viewControllers = viewControllers
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
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

