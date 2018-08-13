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
import ChatCampUIKit

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

    func applicationDidEnterBackground(_ application: UIApplication) {
        CCPClient.disconnect { error in
            //do nothing here
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        if let userID = UserDefaults.standard.userID() {
            CCPClient.connect(uid: userID) { (user, error) in
                //do nothing here
            }
        }
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        let token = tokenParts.joined()
        UserDefaults.standard.setDeviceToken(deviceToken: token)
        print("Device Token: \(token)")
    }
    
    func application(_ application: UIApplication,
                         didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Device token for push notifications: FAIL -- ")
        print(error)
    }
    
    func initializeNotificationServices() -> Void {
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization( options: authOptions, completionHandler: {_, _ in })
        
        // This is an asynchronous method to retrieve a Device Token
        // Callbacks are in AppDelegate.swift
        // Success = didRegisterForRemoteNotificationsWithDeviceToken
        // Fail = didFailToRegisterForRemoteNotificationsWithError
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
            CCPClient.connect(uid: userID) { (user, error) in
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
        if let userInfo = response.notification.request.content.userInfo as? [String: Any], let channelId = userInfo["channelId"] as? String{
            DispatchQueue.main.async {
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

