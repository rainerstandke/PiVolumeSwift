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
	
	func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
		
		if let tabBarCon = window?.rootViewController as? ShyTabBarController {
			tabBarCon.restoreChildViewControllers()
		}
		
		window?.makeKeyAndVisible()
		
		return true
	}
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		K.prepUserDefaults() // to force userDefs initial, non-nil values
		
		// force init
		NMSSHLogger.shared().isEnabled = false
		
		KeyChainManager.shared.writeKeyFiles()
		
		return true
	}
	
	func applicationWillResignActive(_ application: UIApplication) {
		triggerAllSettingsSave()
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
		triggerAllSettingsSave()
	}
	
	func triggerAllSettingsSave() {
		UserDefaults.standard.synchronize()
		if let tabBarCon = (self.window?.rootViewController) as? ShyTabBarController {
			tabBarCon.makeVolumeVuConsSave()
		}
	}
	
	func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
		return true
	}

	func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
		return true
	}
}

