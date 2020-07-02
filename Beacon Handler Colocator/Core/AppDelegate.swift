//
//  AppDelegate.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 20/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        IQKeyboardManager.shared.enable = true
    
        // Token for API access
        // Do NOT modify
        UserDefaults.standard.set("Basic RDhFRDMzMTRFQkM4RENDMDM5MDZDQTZBRjU1MjE0RTM6RjU1QzNCRjc3NTZERkMyOTdDMkUwMUI5MDE2NzFBN0I3QjUzQjU4MkFFMkJDMUI2Qjg5NEVDNUVCODFGODA2NA==", forKey: kAuthorizationTokenStorageKey)
        UserDefaults.standard.set("2c2d41fb-d4c5-4a4d-a49a-e8fd5c256293", forKey: kRegionUUIDStorageKey)
        UserDefaults.standard.set(0, forKey: kMajorValueStorageKey)
    
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

