//
//  AppDelegate.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 2/9/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//

import UIKit
import NMSSH

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	var window: UIWindow?
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		_ = K() // to force userDefs initial, non-nil values
		
		// force init
		NMSSHLogger.shared().isEnabled = true
		
		KeyChainManager().landing()
		
		return true
	}
	
	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
		
		triggerAllSettingsSave()
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		triggerAllSettingsSave()
	}
	
	func triggerAllSettingsSave() {
		if let tabBarCon = (self.window?.rootViewController) as? ShyTabBarController {
			print("tabBarCon: \(tabBarCon)")
			tabBarCon.makeVolumeVuConsSave()
		}
	}
	
	func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
		return true
	}
	
	func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
		return true
	}
	
//	func checkForKeys() {
//		let docDirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//		print("xxx: \(docDirURL)")
//		let fileURLs = try! FileManager.default.contentsOfDirectory(at: docDirURL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions(rawValue: 0))
//		print("xxx: \(fileURLs)")
//
//		for fileURL in fileURLs {
//			print("fileURL.pathExtension: \(fileURL.pathExtension)")
//			if fileURL.pathExtension == "pub" {
//				let pubKey = try! String.init(contentsOf: fileURL)
//				if pubKey.hasPrefix("ssh-rsa ") {
//					// TODO: move to keyChain
//					print("pub found")
//
//					guard let valueData = try? Data.init(contentsOf: fileURL) else {
//						print("Error saving text to Keychain")
//						continue
//					}
//					print("valueData: \(valueData)")
//
//					let queryAdd: [String: AnyObject] = [
//						kSecClass as String: kSecClassKey,
//						kSecValueData as String: valueData as AnyObject,
//						kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
//						kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
//						kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
//						]
//
//					let resultCode = SecItemAdd(queryAdd as CFDictionary, nil)
//
//					if resultCode != noErr {
//						print("Error saving to Keychain: \(resultCode)")
//					}
//				}
//			}  else if fileURL.pathExtension == "" {
//				let pubKey = try! String.init(contentsOf: fileURL)
//
//				if pubKey.hasPrefix("-----BEGIN RSA PRIVATE KEY-----") {
//					// TODO: move to keyChain
//					print("private found")
//
//					guard let valueData = try? Data.init(contentsOf: fileURL) else {
//						print("Error saving text to Keychain")
//						continue
//					}
//					print("valueData: \(valueData)")
//
//					let queryAdd: [String: AnyObject] = [
//						kSecClass as String: kSecClassKey,
//						kSecValueData as String: valueData as AnyObject,
//						kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
//						kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
//						kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
//						]
//
//					let resultCode = SecItemAdd(queryAdd as CFDictionary, nil)
//
//					if resultCode != noErr {
//						print("Error saving to Keychain: \(resultCode)")
//					}
//				}
//
//			}
//			//
//
//		}
//	}
}

