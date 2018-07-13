//
//  AppDelegate.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 10/02/18.
//  Copyright © 2018 ChatCamp. All rights reserved.
//

import UIKit
import ChatCamp
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        setupChatCampSDK()
        
        setupAppearances()
        initializeNotificationServices()
        CCPClient.addChannelDelegate(channelDelegate: self, identifier: AppDelegate.string())
        routeUser()
        
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
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        let token = tokenParts.joined()
        UserDefaults.standard.setDeviceToken(deviceToken: token)
        print("Device Token: \(token)")
        
        // ...register device token with our Time Entry API server via REST
    }
    
        func application(_ application: UIApplication,
                         didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Device token for push notifications: FAIL -- ")
        print(error)
    }
    
    func initializeNotificationServices() -> Void {
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        
        UIApplication.shared.registerForRemoteNotifications()
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
    
    fileprivate func routeUser() {
        if let userID = UserDefaults.standard.userID() {
            CCPClient.connect(uid: userID) { [unowned self] (user, error) in
                DispatchQueue.main.async {
                    if error == nil {
                        if let deviceToken = UserDefaults.standard.deviceToken() {
                            CCPClient.updateUserPushToken(token: deviceToken) { (_,_) in
                                print("update device token on the server.")
                            }
                        }
                        WindowManager.shared.prepareWindow(isLoggedIn: true)
                    } else {
                        WindowManager.shared.prepareWindow(isLoggedIn: false)
                    }
                }
            }
        } else {
            WindowManager.shared.prepareWindow(isLoggedIn: false)
        }
    }
}

// MARK:- CCPChannelDelegate
extension AppDelegate: CCPChannelDelegate {
    func channelDidReceiveMessage(channel: CCPBaseChannel, message: CCPMessage) {
        if CCPClient.getCurrentUser().getId() != message.getUser().getId() && channel.getId() != currentChannelId && channel.isGroupChannel() {
            
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            
            let content = UNMutableNotificationContent()
            content.title = message.getUser().getDisplayName() ?? ""
            content.body = message.getText()
            content.sound = UNNotificationSound.default()
            content.userInfo = ["channelId": channel.getId()]
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.01, repeats: false)
            let request = UNNotificationRequest(identifier: message.getId(), content: content, trigger: trigger)
            
            center.add(request) { (error) in
                if error != nil {
                    print("error \(String(describing: error))")
                }
            }
        }
    }
    
    func channelDidChangeTypingStatus(channel: CCPBaseChannel) {
        // Not applicable
    }
    
    func channelDidUpdateReadStatus(channel: CCPBaseChannel) {
        // Not applicable
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userID = CCPClient.getCurrentUser().getId()
        let username = CCPClient.getCurrentUser().getDisplayName()
        
        let sender = Sender(id: userID, displayName: username!)
        if let userInfo = response.notification.request.content.userInfo as? [String: Any], let channelId = userInfo["channelId"] as? String{                DispatchQueue.main.async {
                CCPGroupChannel.get(groupChannelId: channelId) {(groupChannel, error) in
                    if let channel = groupChannel {
                        let chatViewController = ChatViewController(channel: channel, sender: sender)
                        let homeTabBarController = UIViewController.homeTabBarNavigationController()
                        WindowManager.shared.window.rootViewController = homeTabBarController
                        homeTabBarController.pushViewController(chatViewController, animated: true)
                    }
                }
            }
        }
        
        completionHandler()
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge]) //required to show notification when in foreground
    }
}

