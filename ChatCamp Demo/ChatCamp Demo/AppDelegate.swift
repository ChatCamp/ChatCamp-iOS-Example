//
//  AppDelegate.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 10/02/18.
//  Copyright © 2018 ChatCamp. All rights reserved.
//

import UIKit
import ChatCamp

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        setupChatCampSDK()
        setupAppearances()
        
        WindowManager.shared.prepareWindow(isLoggedIn: false)
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

// MARK - Setup
extension AppDelegate {
    fileprivate func setupChatCampSDK() {
        CCPClient.initApp(appId: "6346990561630613504")
    }

    fileprivate func setupAppearances() {
        UINavigationBar.appearance().tintColor = UIColor(red: 63/255, green: 81/255, blue: 180/255, alpha: 1.0)
    }
}

