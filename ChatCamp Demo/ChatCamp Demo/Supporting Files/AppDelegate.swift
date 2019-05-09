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
import Fabric
import Crashlytics
import MessageKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var groupChannelId = ""

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        Fabric.with([Crashlytics.self])
        setupChatCampSDK()
        
        setupAppearances()
        initializeNotificationServices()
        CCPClient.addChannelDelegate(channelDelegate: self, identifier: AppDelegate.string())
        routeUser()
        
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        CCPClient.disconnect { _ in
            CCPClient.addConnectionDelegate(connectionDelegate: self, identifier: AppDelegate.string())
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        if let userID = UserDefaults.standard.userID() {
            CCPClient.connect(uid: userID) { (_, _) in }
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
    
    func onMessageReceived(channel: CCPBaseChannel, message: CCPMessage) {
        if CCPClient.getCurrentUser().getId() != message.getUser()?.getId() && channel.getId() != currentChannelId && channel.ifGroupChannel() {
            
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            
            let content = UNMutableNotificationContent()
            if (channel as? CCPGroupChannel)?.getParticipantsCount() ?? 0 > 2 {
                content.title = channel.getName()
                content.subtitle = message.getUser()?.getDisplayName() ?? ""
            } else {
                content.title = message.getUser()?.getDisplayName() ?? ""
            }
            content.sound = UNNotificationSound.default
            content.userInfo = ["channelId": channel.getId()]
            let messageType = message.getType()
            if messageType == "attachment" {
                content.body = "Attachment Received"
            } else {
                content.body = message.getText()
            }
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.01, repeats: false)
            let request = UNNotificationRequest(identifier: message.getId(), content: content, trigger: trigger)
            
            center.add(request) { (error) in
                if error != nil {
                    print("error \(String(describing: error))")
                }
            }
        }
    }
    
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let userInfo = response.notification.request.content.userInfo as? [String: Any], let channelId = userInfo["channelId"] as? String {
            groupChannelId = channelId
            if !(response.notification.request.trigger?.isKind(of: UNPushNotificationTrigger.self) ?? true) {
                if let userID = CCPClient.getCurrentUser().getId(), let username = CCPClient.getCurrentUser().getDisplayName() {
                    let sender = Sender(id: userID, displayName: username)
                    CCPGroupChannel.get(groupChannelId: self.groupChannelId) {(groupChannel, error) in
                        if let channel = groupChannel {
                            let chatViewController = ChatViewController(channel: channel, sender: sender)
                            let homeTabBarController = UIViewController.homeTabBarNavigationController()
                            WindowManager.shared.window.rootViewController = homeTabBarController
                            homeTabBarController.pushViewController(chatViewController, animated: true)
                        }
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

extension AppDelegate: CCPConnectionDelegate {
    
    func connectionDidChange(isConnected: Bool) {
        CCPClient.removeConnectionDelegate(identifier: AppDelegate.string())
        if isConnected && !groupChannelId.isEmpty {
            DispatchQueue.main.async {
                if let userID = CCPClient.getCurrentUser().getId(), let username = CCPClient.getCurrentUser().getDisplayName() {
                    let sender = Sender(id: userID, displayName: username)
                    CCPGroupChannel.get(groupChannelId: self.groupChannelId) {(groupChannel, error) in
                        if let channel = groupChannel {
                            let chatViewController = ChatViewController(channel: channel, sender: sender)
                            let homeTabBarController = UIViewController.homeTabBarNavigationController()
                            WindowManager.shared.window.rootViewController = homeTabBarController
                            homeTabBarController.pushViewController(chatViewController, animated: true)
                        }
                    }
                }
            }
        }
    }
    
}
